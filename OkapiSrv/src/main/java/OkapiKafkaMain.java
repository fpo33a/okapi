import java.util.HashMap;



// http://localhost:9123/subscribe?topic=test&consumergroup=fp100&readpolicy=earliest&broker=130.61.83.201:9092
// http://localhost:9123/unsubscribe?topic=test&consumergroup=fp100

// this class is for development testing purpose only, not used by vertx itself
public class OkapiKafkaMain {


    // The topic we are going to read records from
    private static final String KAFKA_TOPIC_NAME = "test";
    private static final String ALPHA_NUMERIC_STRING = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    public static void main(String[] args) {
        OkapiKafkaConsumer consumer = null;
        String consumerGroup = OkapiKafkaMain.randomAlphaNumeric(5);
        HashMap<String,OkapiKafkaConsumer> consumerMap = new HashMap<String,OkapiKafkaConsumer>();

        consumer = consumerMap.get(KAFKA_TOPIC_NAME+"_"+consumerGroup);
        if (consumer == null) {
            System.out.println ("Create kafka consumer");
            consumer = new OkapiKafkaConsumer();
            consumerMap.put(KAFKA_TOPIC_NAME+"_"+consumerGroup, consumer);
        }

        OkapiKafkaConsumer test = (OkapiKafkaConsumer) consumerMap.get(KAFKA_TOPIC_NAME+"_"+consumerGroup);
        System.out.println (test);
        test.init ("130.61.83.201:9092",
                          consumerGroup,
                          KAFKA_TOPIC_NAME,
                "earliest");

        test.start();
        try {
            Thread.sleep(1000 * 30);
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
        test.stopReading();
        consumerMap.remove(KAFKA_TOPIC_NAME+"_"+consumerGroup);
        System.out.println(consumerMap.size());
    }

    public static String randomAlphaNumeric(int count) {
        StringBuilder builder = new StringBuilder();
        while (count-- != 0) {
            int character = (int)(Math.random()*ALPHA_NUMERIC_STRING.length());
            builder.append(ALPHA_NUMERIC_STRING.charAt(character));
        }
        return builder.toString();
    }

}
