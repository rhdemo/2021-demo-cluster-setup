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
    @CloudEventMapping(responseType = "winprocessed")
    public Uni<MessageOutput> function( String input, @Context CloudEvent cloudEvent)
    {
      System.out.println( "RECV: " + input );

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
      boolean watched = watchman.inform( "WIN:" + input );
      
      // Build a return packet
      MessageOutput output = new MessageOutput();

      //Process the payload
      Map<String,String> data = processPayload( input );

      if( data != null )
      {
        output.setTimestamp( System.currentTimeMillis() );
        output.setPlayer( data.get("player"));
        output.setMatch( data.get("match"));
        output.setGame( data.get("game"));
        output.set( data.get("human").equals("true"));
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

        String gameID = (String)jsonPayload.get("game");
        String matchID = (String)jsonPayload.get("match");
        String playerID = (String)jsonPayload.get("player");
        boolean human = (boolean)jsonPayload.get("human");

        System.out.println( "(Parsed) Game: " + gameID + " Match: " + matchID + " Player: " + playerID + " human: " + human );

        output.put( "player", playerID );
        output.put( "match", matchID );
        output.put( "game", gameID );
        output.put( "human", ( human ? "true" : "false" ));
        
        return output;
      }
      catch( Exception exc )
      {
        System.out.println("Failed to parse JSON due to " + exc.toString());
        return null;
      }
    }
}
