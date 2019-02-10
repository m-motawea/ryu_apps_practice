from ryu.ofproto import ofproto_v1_3
from ryu.controller import ofp_event
from ryu.controller.handler import CONFIG_DISPATCHER, set_ev_cls
from switching import Switch13
from rules import DenyRule
from ryu.lib.packet.ethernet import ether

class Firewall(Switch13):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def switch_features_handler(self, ev):
        super(Firewall, self).switch_features_handler(ev)
        msg = ev.msg
        dp = msg.datapath
        d_rule = DenyRule(dp=dp, ipv4_dst=('10.10.10.2', '255.255.255.0'), eth_type=ether.ETH_TYPE_IP)
        d_rule.add_flow()
