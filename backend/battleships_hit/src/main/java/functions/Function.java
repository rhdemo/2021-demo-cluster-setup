package functions;

import io.quarkus.funqy.Context;
import io.quarkus.funqy.Funq;
import io.quarkus.funqy.knative.events.CloudEvent;
import io.quarkus.funqy.knative.events.CloudEventMapping;
import io.smallrye.mutiny.Uni;
import io.smallrye.mutiny.subscription.UniEmitter;
import io.vertx.core.Vertx;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import org.json.simple.*;
import org.json.simple.parser.*;

import javax.inject.Inject;
import java.net.*;
import java.util.*;

public class Function 
{
    private long start = System.currentTimeMillis();

    @Inject
    Vertx vertx;

    @ConfigProperty(name = "WATCHMAN")
    String _watchmanURL;

    @Funq
    @CloudEventMapping(responseType = "message.processedbyquarkus")
    //public Uni<MessageOutput> function( Input input, @Context CloudEvent cloudEvent)
    public Uni<MessageOutput> function( String input, @Context CloudEvent cloudEvent)
    {
      return Uni.createFrom().emitter(emitter -> 
      {
        buildResponse(input, cloudEvent, emitter);
      });    
    }
 
    public void buildResponse( String input, CloudEvent cloudEvent, UniEmitter<? super MessageOutput> emitter )
    {
      System.out.println("Recv:" + input );

      // Watchman
      boolean watched = watchman( "HIT:" + input );
      
      // Build a return packet
      MessageOutput output = new MessageOutput();

      //Process the payload
      Map<String,String> data = processPayload( input );

      output.setElapsed(System.currentTimeMillis() - start );
      output.setName("Payload Check");
      output.setDetails(input);
      output.setResponseCode(200);

      emitter.complete(output);
    }

    private Map<String,String> processPayload( String payload )
    {
      try
      {
        Map<String,String> output = new HashMap<>();
        Object objPayload = new JSONParser().parse(payload);

        JSONObject jsonPayload = (JSONObject)objPayload; 

        String by = (String)jsonPayload.get("by");
        String against = (String)jsonPayload.get("against");
        String origin = (String)jsonPayload.get("origin");
        long timestamp = (Long)jsonPayload.get("ts");
        String matchID = (String)jsonPayload.get("match");

        System.out.println( "(Parsed) by:" + by + " against:" + against + " origin:" + origin + " timestamp:" + timestamp + " matchID:" + matchID );

        output.put( "by", by );
        output.put( "against", against );
        output.put( "origin", origin );
        output.put( "timestamp", Long.toString(timestamp) );
        output.put( "matchID", matchID );

        return output;
      }
      catch( Exception exc )
      {
        System.out.println("Failed to parse JSON due to " + exc.toString());
        watchman("JSON FAIL with " + payload );
        return null;
      }
    }

    private boolean watchman( String output )
    {
      try
      {
        String outputTarget = _watchmanURL + "?payload=" + URLEncoder.encode(output, "UTF-8");

        URL targetURL = new URL(outputTarget);
        HttpURLConnection connection = (HttpURLConnection)targetURL.openConnection();
        connection.setRequestMethod("GET");

        int status = connection.getResponseCode();

        System.out.println( "Calling: " + outputTarget );
        System.out.println( "REST Service responded wth " + status );
      }
      catch( Exception exc )
      {
        System.out.println( "Watchman failed due to " + exc.toString());
        return false;
      }

      return true;
    }
}
