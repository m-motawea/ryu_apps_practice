from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import MAIN_DISPATCHER, CONFIG_DISPATCHER, set_ev_cls
from ryu.ofproto import ofproto_v1_3
from ryu.lib.packet import packet, ethernet, arp, ipv4, icmp


class IcmpResponder(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(IcmpResponder, self).__init__(*args, **kwargs)
        self.hw_addr = '0a:e4:1c:d1:3e:44'
        self.ip_addr = '10.10.10.254'


    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def _switch_features_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        actions = [
            parser.OFPActionOutput(
                port=ofproto.OFPP_CONTROLLER,
                max_len=ofproto.OFPCML_NO_BUFFER
            )
        ]
        inst = [parser.OFPInstructionActions(type_=ofproto.OFPIT_APPLY_ACTIONS, actions=actions)]
        mod = parser.OFPFlowMod(
            datapath=datapath,
            priority=0,
            match=parser.OFPMatch(),
            instructions=inst
        )
        datapath.send_msg(mod)

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
        pkt_arp = pkt.get_protocol(arp.arp)
        if pkt_arp:
            self._handle_arp(datapath, port, pkt_ethernet, pkt_arp)
        pkt_ipv4 = pkt.get_protocol(ipv4.ipv4)
        pkt_icmp = pkt.get_protocol(icmp.icmp)
        if pkt_icmp:
            self._handle_icmp(datapath, port, pkt_ethernet, pkt_ipv4, pkt_icmp)
            return

    def _handle_arp(self, datapath, port, pkt_ethernet, pkt_arp):
        if pkt_arp.opcode != arp.ARP_REQUEST:
            return

        if pkt_arp.dst_ip != self.ip_addr:
            return
        pkt = packet.Packet()
        pkt.add_protocol(ethernet.ethernet(
            ethertype=pkt_ethernet.ethertype,
            dst=pkt_ethernet.src,
            src=self.hw_addr
        ))
        pkt.add_protocol(arp.arp(
            opcode=arp.ARP_REPLY,
            src_mac=self.hw_addr,
            src_ip=self.ip_addr,
            dst_mac=pkt_arp.src_mac,
            dst_ip=pkt_arp.src_ip
        ))
        self._send_packet(datapath, port, pkt)

    def _handle_icmp(self, datapath, port, pkt_ethernet, pkt_ipv4, pkt_icmp):
        if pkt_icmp.type != icmp.ICMP_ECHO_REQUEST:
            return

        if pkt_ipv4.dst != self.ip_addr:
            return

        pkt = packet.Packet()
        pkt.add_protocol(ethernet.ethernet(
            ethertype=pkt_ethernet.ethertype,
            src=self.hw_addr,
            dst=pkt_ethernet.src
        ))
        pkt.add_protocol(ipv4.ipv4(
            dst=pkt_ipv4.src,
            src=self.ip_addr,
            proto=pkt_ipv4.proto
        ))
        pkt.add_protocol(icmp.icmp(
            type_=icmp.ICMP_ECHO_REPLY,
            code=icmp.ICMP_ECHO_REPLY_CODE,
            csum=0,
            data=pkt_icmp.data
        ))
        self._send_packet(datapath, port, pkt)

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
