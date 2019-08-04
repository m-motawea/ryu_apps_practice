import pika
from ryu.base import app_manager
from ryu.controller.handler import set_ev_cls
from ryu.lib import hub
from .amqp_events import RabbitMQMessageEvent


creds = pika.PlainCredentials(
        username="root",
        password="root"
    )
params = pika.ConnectionParameters(
        host="192.168.23.128",
        credentials=creds
    )



class Listener(app_manager.RyuApp):
    _EVENTS = [RabbitMQMessageEvent]

    def __init__(self, *args, **kwargs):
        super(Listener, self).__init__(*args, **kwargs)
        hub.spawn(self.consume)

    def consumer(self, ch, method, props, body):
        self.send_event_to_observers(RabbitMQMessageEvent(body))
        ch.basic_ack(delivery_tag=method.delivery_tag)

    def consume(self):
        conn = pika.BlockingConnection(params)
        ch = conn.channel()
        while True:
            try:
                ch.queue_declare("ryu")
                ch.basic_consume("ryu", self.consumer, auto_ack=False)
                ch.start_consuming()
            except Exception as e:
                print(f"exception: {str(e)}")
                try:
                    conn.close()
                except Exception as e:
                    print(f"exception closing connection {str(e)}")
                conn = pika.BlockingConnection(params)
                ch = conn.channel()

    @set_ev_cls(RabbitMQMessageEvent)
    def observer(self, ev):
        print(f"received message: {ev.message}")

