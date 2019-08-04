from ryu.controller.event import EventBase


class RabbitMQMessageEvent(EventBase):
    def __init__(self, message):
        super(RabbitMQMessageEvent, self).__init__()
        self.message = message