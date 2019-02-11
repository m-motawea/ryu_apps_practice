import uuid
import json
from ryu.base import app_manager
from ryu.controller.handler import set_ev_cls
from ryu.services.protocols.ovsdb import api as ovsdb
from ryu.services.protocols.ovsdb import event as ovsdb_event




class OvsdbManager(app_manager.RyuApp):
    @set_ev_cls(ovsdb_event.EventNewOVSDBConnection)
    def handle_new_ovsdb_connection(self, ev):
        system_id = ev.system_id
        address = ev.client.address
        self.logger.info(
            'New OVSDB connection from system-id=%s, address=%s',
            system_id, address)

        self.create_bridge(system_id, 'ryu-bridge')
        if ovsdb.bridge_exists(self, system_id, "ryu-bridge"):
            self.create_port(system_id, "ryu-bridge", "h1-sw")
            self.create_port(system_id, "ryu-bridge", "h2-sw")

    def create_port(self, system_id, bridge_name, name):
        new_iface_uuid = uuid.uuid4()
        new_port_uuid = uuid.uuid4()

        bridge = ovsdb.row_by_name(self, system_id, bridge_name)

        def _create_port(tables, insert):
            iface = insert(tables['Interface'], new_iface_uuid)
            iface.name = name

            port = insert(tables['Port'], new_port_uuid)
            port.name = name
            port.interfaces = [iface]

            bridge.ports = bridge.ports + [port]

            return new_port_uuid, new_iface_uuid

        req = ovsdb_event.EventModifyRequest(system_id, _create_port)
        rep = self.send_request(req)

        if rep.status != 'success':
            self.logger.error('Error creating port %s on bridge %s: %s',
                              name, bridge, rep.status)
            return None

        return rep.insert_uuids[new_port_uuid]


    def create_bridge(self, system_id, bridge_name):
        new_bridge_uuid = uuid.uuid4()

        def _create_bridge(tables, insert):
            bridge = insert(tables['Bridge'], new_bridge_uuid)
            bridge.name = bridge_name
            list(tables['Open_vSwitch'].rows.values())[0].bridges += [bridge]

            return (new_bridge_uuid, )

        req = ovsdb_event.EventModifyRequest(system_id, _create_bridge)
        rep = self.send_request(req)

        if rep.status != 'success':
            self.logger.error('Error creating bridge %s: %s',
                              bridge_name, rep.status)
            return None
        else:
            self.logger.info('created bridge %s with uuid %s successfully', bridge_name, new_bridge_uuid.hex)
        return rep.insert_uuids[new_bridge_uuid]