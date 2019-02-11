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
            self.set_controller(system_id, "ryu-bridge", "tcp:127.0.0.1:6633")
            self.set_openflow_versions(system_id, "ryu-bridge", ["OpenFlow13"])

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


    def set_controller(self, system_id, bridge_name, controller_url, bridge_uuid=None):
        new_controller_uuid = uuid.uuid4()

        def _set_controller(tables, insert):
            controller = insert(tables['Controller'], new_controller_uuid)
            controller.target = controller_url
            bridge = None
            if bridge_uuid:
                bridge = tables['Bridge'].rows.get(bridge_uuid)
            else:
                bridges = list(tables['Bridge'].rows.values())
                for br in bridges:
                    if br.name == bridge_name:
                        bridge = br
                        break
            if bridge:
                bridge.controller = [controller]

            return (new_controller_uuid, )

        req = ovsdb_event.EventModifyRequest(system_id, _set_controller)
        rep = self.send_request(req)

        if rep.status != 'success':
            self.logger.error('Error adding controller %s: %s',
                              controller_url, rep.status)
            return None
        else:
            self.logger.info('added controller %s with uuid %s to bridge %s successfully', controller_url,
                             new_controller_uuid.hex, bridge_name)
        return rep.insert_uuids[new_controller_uuid]

    def set_openflow_versions(self, system_id, bridge_name, protocols=[], bridge_uuid=None):

        def _set_openflow_versions(tables, insert):
            bridge = None
            if bridge_uuid:
                bridge = tables['Bridge'].rows.get(bridge_uuid)
            else:
                bridges = list(tables['Bridge'].rows.values())
                for br in bridges:
                    if br.name == bridge_name:
                        bridge = br
                        break

            if bridge:
                bridge.protocols = protocols

            return (bridge.uuid, ) if bridge else ()

        req = ovsdb_event.EventModifyRequest(system_id, _set_openflow_versions)
        rep = self.send_request(req)

        if rep.status != 'success':
            self.logger.error('Error setting openflow protocols %s: %s',
                              protocols, rep.status)
            return None
        else:
            self.logger.info('OpenFlow protocols %s added to bridge %s successfully', str(protocols), bridge_name)
        return rep