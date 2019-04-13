import io.vertx.core.AbstractVerticle;
import io.vertx.ext.web.Router;

import java.util.HashMap;

public class OkapiSrv extends AbstractVerticle {

    @Override
    public void start() throws Exception {

        HashMap<String,OkapiKafkaConsumer> consumerMap = new HashMap<String,OkapiKafkaConsumer>();
        final Router router = Router.router(vertx);

        router.get("/subscribe/")
                .handler(req -> {
                    String topic = req.request().getParam("topic");
                    String consumerGroup = req.request().getParam("consumergroup");
                    String readPolicy = req.request().getParam("readpolicy");
                    String kafkaBroker = req.request().getParam("broker");
                    String metaData = req.request().getParam("metadata");
                    System.out.println("subscribe");
                    System.out.println("topic "+topic );
                    System.out.println("consumerGroup "+consumerGroup );
                    System.out.println("readPolicy "+readPolicy );
                    System.out.println("kafkaBroker "+kafkaBroker );
                    System.out.println("metaData "+metaData );
                    OkapiKafkaConsumer consumer = consumerMap.get(topic+"_"+consumerGroup);
                    if (consumer == null) {
                        System.out.println ("Create kafka consumer");
                        consumer = new OkapiKafkaConsumer();
                        consumerMap.put(topic+"_"+consumerGroup, consumer);
                        consumer.init(kafkaBroker,consumerGroup,topic,readPolicy,metaData);
                        req.response()
                                .putHeader("content-type", "text/html")
                                .end("<html><body>Subscribing for "+topic+", "+consumerGroup+", "+readPolicy+" created</body></html>");
                    }
                    else {
                        req.response()
                                .putHeader("content-type", "text/html")
                                .end("<html><body>Subscribing for "+topic+", "+consumerGroup+" already exists</body></html>");
                    }
                    consumer.start();
                });

        router.get("/unsubscribe/")
                .handler(req -> {
                    System.out.println("unsubscribe");
                    String topic = req.request().getParam("topic");
                    String consumerGroup = req.request().getParam("consumergroup");
                    OkapiKafkaConsumer consumer = consumerMap.get(topic+"_"+consumerGroup);
                    if (consumer != null) {
                        consumer.stopReading();
                        consumerMap.remove(topic+"_"+consumerGroup);
                        req.response()
                                .putHeader("content-type", "text/html")
                                .end("<html><body><h1>Ending subscribing for " + topic + ", " + consumerGroup + "</body></html>");
                    }
                    else {
                        req.response()
                                .putHeader("content-type", "text/html")
                                .end("<html><body><h1>Can't find subscribion for " + topic + ", " + consumerGroup + "</body></html>");
                    }
                });

        System.out.println("Okapi is starting ...");
        vertx.createHttpServer()
                .requestHandler(router::accept)
                .listen(9123);
    }
}