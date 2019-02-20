from ryu.base import app_manager
from ryu.controller import ofp_event, dpset
from ryu.controller.handler import MAIN_DISPATCHER, CONFIG_DISPATCHER, set_ev_cls
from ryu.ofproto import ofproto_v1_3
from ryu.lib.packet import packet, ethernet, lldp, slow
from ryu.lib.dpid import dpid_to_str, str_to_dpid
from ryu.lib import hub
from ryu.controller.controller import Datapath
from ryu.topology.switches import LLDPPacket
import struct
import datetime
import json
from multiprocessing import Lock



class LldpTopoMapper(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]
    _CONTEXTS = {
        'dpset': dpset.DPSet,
    }

    def __init__(self, *args, **kwargs):
        super(LldpTopoMapper, self).__init__(*args, **kwargs)
        self.dpset = kwargs['dpset']
        self.ttl = 15
        self.dps = {}
        self.topo_graph = {}
        self.topo_lock = Lock()
        hub.spawn(self.lldp_event)
        hub.spawn(self.lldp_dead_check)


    def lldp_event(self):
        self.logger.debug('started lldp callback')
        while True:
            hub.sleep(10)
            for dp in self.dps.values():
                self.logger.debug('sending lldp out of datapath: %s', dpid_to_str(dp.id))
                self.send_lldp(dp)


    def lldp_dead_check(self):
        self.logger.debug("started lldp dead checker")
        while True:
            self.logger.debug("lldp dead checker acquiring topology lock....")
            self.topo_lock.acquire()
            self.logger.debug(("lock acquired by lldp dead checker."))
            for dpid in self.topo_graph:
                ports = list(self.topo_graph[dpid].keys())
                for port_no in ports:
                    switch_state = self.topo_graph[dpid][port_no]
                    if switch_state["last_updated"] + datetime.timedelta(seconds=self.ttl) <= datetime.datetime.utcnow():
                        self.logger.debug("dpid %s dead. last_updated: %s", switch_state["dpid"], str(switch_state["last_updated"]))
                        self.topo_graph[dpid].pop(port_no)
            self.logger.debug("lldp dead checker releasing lock..")
            self.topo_lock.release()
            self.logger.debug("lock released by lldp dead checker")
            hub.sleep(self.ttl)



    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def _switch_features_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        self.dps[datapath.id] = datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        match = parser.OFPMatch(
            eth_type=ethernet.ether.ETH_TYPE_LLDP
        )
        actions = [parser.OFPActionOutput(ofproto.OFPP_CONTROLLER,
            ofproto.OFPCML_NO_BUFFER)]

        self.add_flow(datapath, 10, match, actions)


    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def _packet_in_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        port = msg.match['in_port']
        pkt = packet.Packet(msg.data)
        self.logger.info("packet-in %s" % (pkt,))
        pkt_ethernet = pkt.get_protocol(ethernet.ethernet)
        if not pkt_ethernet:
            return
        pkt_lldp = pkt.get_protocol(lldp.lldp)
        if pkt_lldp:
            self._handle_lldp(datapath, port, pkt_ethernet, pkt_lldp, pkt, port)


    def add_flow(self, datapath, priority, match, actions):
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser

        inst = [parser.OFPInstructionActions(ofproto.OFPIT_APPLY_ACTIONS,
            actions)]
        mod = parser.OFPFlowMod(
                datapath=datapath,
                priority=priority,
                match=match,
                instructions=inst
                )
        datapath.send_msg(mod)


    def send_lldp(self, datapath: Datapath):
        ports = self.dpset.get_ports(datapath.id)
        for port in ports:
            pkt = packet.Packet()
            pkt.add_protocol(ethernet.ethernet(
                ethertype=ethernet.ether.ETH_TYPE_LLDP,
                dst="01:80:C2:00:00:02",
                src=port.hw_addr
            ))
            tlv_chassis_id = lldp.ChassisID(
                subtype=lldp.ChassisID.SUB_LOCALLY_ASSIGNED,
                chassis_id=(LLDPPacket.CHASSIS_ID_FMT %
                            dpid_to_str(datapath.id)).encode('ascii'))

            tlv_port_id = lldp.PortID(subtype=lldp.PortID.SUB_PORT_COMPONENT,
                                      port_id=struct.pack(
                                          LLDPPacket.PORT_ID_STR,
                                          port.port_no))

            tlv_ttl = lldp.TTL(ttl=self.ttl)
            tlv_end = lldp.End()

            tlvs = (tlv_chassis_id, tlv_port_id, tlv_ttl, tlv_end)
            lldp_pkt = lldp.lldp(tlvs)
            pkt.add_protocol(lldp_pkt)
            try:
                self._send_packet(datapath, port.port_no, pkt)
            except Exception as e:
                print(str(e))


    def _send_packet(self, datapath, port, pkt):
        ofproto=datapath.ofproto
        parser = datapath.ofproto_parser
        pkt.serialize()
        self.logger.info("packet-out %s" % (pkt,))
        data = pkt.data
        actions = [parser.OFPActionOutput(port=port)]
        out = parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=ofproto.OFP_NO_BUFFER,
            in_port=ofproto.OFPP_CONTROLLER,
            actions=actions,
            data=data
        )
        datapath.send_msg(out)


    def _handle_lldp(self, datapath, port, pkt_ethernet, pkt_lldp, pkt, in_port):
        self.logger.debug("lldp packet in %s", str(pkt_lldp))

        self.logger.debug("lldp handler acquiring topology lock....")
        self.topo_lock.acquire()
        self.logger.debug(("lock acquired by lldp handler."))
        # create default switch port map {dpid: {port_no: {"dpid": remote_dpid, "last_updated": datetime.datetime()}}}

        if self.topo_graph.get(datapath.id) == None:
            self.topo_graph[datapath.id] = {}
        self.logger.debug("update topology map....")
        src_dpid = pkt_lldp.tlvs[0].chassis_id.decode("utf-8").split('dpid:')[1]
        self.topo_graph[datapath.id][in_port] = {"dpid": str_to_dpid(src_dpid), "last_updated": datetime.datetime.utcnow()}
        self.logger.debug("lldp handler releasing lock..")
        self.topo_lock.release()
        self.logger.debug("lock released by lldp handler")
        self.logger.debug("----------------------------------------------------------------------")
        self.logger.debug("current topology map: \n%s", json.dumps(self.topo_graph, default=str))
