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

import org.uth.summit.utils.*;

public class Function 
{
    private long start = System.currentTimeMillis();

    @Inject
    Vertx vertx;

    @ConfigProperty(name = "WATCHMAN")
    String _watchmanURL;

    @Funq
    @CloudEventMapping(responseType = "hitprocessed")
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
      // Setup Watchman
      Watchman watchman = new Watchman( _watchmanURL );

      System.out.println("Recv:" + input );

      // Watchman
      boolean watched = watchman.inform( "HIT:" + input );
      
      // Build a return packet
      MessageOutput output = new MessageOutput();

      //Process the payload
      Map<String,String> data = processPayload( input );

      if( data != null )
      {
        output.setBy( data.get("by"));
        output.setAgainst( data.get("against"));
        output.setOrigin( data.get("origin"));
        output.setTimestamp( Long.parseLong( data.get("timestamp")));
        output.setMatchID( data.get("matchID"));
        output.setGameID( data.get("gameID"));
        output.setType( data.get("type"));

        // PING INFINISPAN HERE
      }

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
        String gameID = (String)jsonPayload.get("game");
        String type = (String)jsonPayload.get("type");

        System.out.println( "(Parsed) by:" + by + " against:" + against + " origin:" + origin + " timestamp:" + timestamp + " matchID:" + matchID + " type:" + type + " gameID: " + gameID );

        output.put( "by", by );
        output.put( "against", against );
        output.put( "origin", origin );
        output.put( "timestamp", Long.toString(timestamp) );
        output.put( "matchID", matchID );
        output.put( "gameID", gameID );
        output.put( "type", type );

        return output;
      }
      catch( Exception exc )
      {
        System.out.println("Failed to parse JSON due to " + exc.toString());
        return null;
      }
    }
}
