from ryu.controller.controller import Datapath
from .constants import FIREWALL_TABLE_ID


class RuleBase(object):
    def __init__(self, dp: Datapath, *args, **kwargs):
        self.dp = dp
        self.ofproto = self.dp.ofproto
        self.parser = self.dp.ofproto_parser
        self.match = kwargs
        self.inst = []

    def add_flow(self):
        match = self.parser.OFPMatch(**self.match)
        msg = self.parser.OFPFlowMod(
            table_id=FIREWALL_TABLE_ID,
            datapath=self.dp,
            priority=10,
            command=self.ofproto.OFPFC_ADD,
            match=match,
            instructions=self.inst
        )
        self.dp.send_msg(msg)


class DenyRule(RuleBase):
    def __init__(self, *args, **kwargs):
        super(DenyRule, self).__init__(*args, **kwargs)
        self.inst = [
            self.parser.OFPInstructionActions(self.ofproto.OFPIT_APPLY_ACTIONS, [])
        ]
