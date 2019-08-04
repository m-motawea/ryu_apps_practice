### AMQP_Listener

##### Description:
This is a simple example of listening to generate Ryu events based on messages received on RabbitMQ queue.


##### Requirements:
1- You need to have ```RabbitMQ``` installed and running ```sudo dnf install rabbitmq-server```

2- Install ```pika``` client ```sudo pip3 install pika```  

3- Enable management plugin ```rabbitmq-plugins enable rabbitmq_management```


##### Running:
1- Start the application using ```ryu-manager --verbose amqp_listener.py```

2- Go to RabbitMQ management plugin web UI ```http://localhost:15672/```

3- Navigate to queues and publish messages to ```ryu``` queue
