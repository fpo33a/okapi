import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.StringDeserializer;

import java.io.BufferedWriter;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.util.Collections;
import java.util.Properties;

/**
 * A very simple Kafka consumer that reads data from a topic and write it into a file
 */
public class OkapiKafkaConsumer extends Thread {

    private boolean bStopReading = false;
    private String kafkaServer = null;
    private String consumerGroup = null;
    private String topicName = null;
    private String readPolicy= null;

    public void init (String kafkaServer, String consumerGroup, String topicName, String readPolicy)
    {
        this.bStopReading = false;
        this.kafkaServer = kafkaServer;
        this.consumerGroup = consumerGroup;
        this.topicName = topicName;
        this.readPolicy = readPolicy;
    }

    public void stopReading ()
    {
        this.bStopReading = true;
    }

    public void run ()
    {
        String filename = this.topicName + "_" + this.consumerGroup + ".topic";

        System.out.println ("subscribing to "+this.topicName + " with consumer group " + this.consumerGroup);
        // Set consumer configuration properties
        final Properties consumerProps = new Properties();
        consumerProps.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, this.kafkaServer);
        consumerProps.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        consumerProps.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        consumerProps.put(ConsumerConfig.GROUP_ID_CONFIG, this.consumerGroup);
        consumerProps.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, this.readPolicy);

        // Create a new consumer
        try (final KafkaConsumer<String, String> consumer = new KafkaConsumer<>(consumerProps)) {
            // Subscribe to the topic
            consumer.subscribe(Collections.singleton(this.topicName));

            FileOutputStream outputStream = new FileOutputStream(filename);

            // Continuously read records from the topic
            while (this.bStopReading == false) {
                final ConsumerRecords<String, String> records = consumer.poll(1000);
                for (ConsumerRecord<String, String> record : records) {
                    System.out.println("Received: " + record.value());
                    outputStream.write(record.value().getBytes());
                    outputStream.flush();
                }
            }
            System.out.println ("Ending subscribion to "+this.topicName + " with consumer group " + this.consumerGroup);
            outputStream.close();
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
    }

}