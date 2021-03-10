package functions;

import io.quarkus.funqy.Context;
import io.quarkus.funqy.Funq;
import io.quarkus.funqy.knative.events.CloudEvent;
import io.quarkus.funqy.knative.events.CloudEventMapping;
import io.smallrye.mutiny.Uni;
import io.smallrye.mutiny.subscription.UniEmitter;
import io.vertx.core.Vertx;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import io.vertx.core.json.JsonObject;

import javax.inject.Inject;
import java.net.*;
import java.util.*;

import org.uth.summit.utils.*;

public class AttackEvent 
{
    private static final int DEFAULT_DESTROYED_SCORE = 5;
    private long start = System.currentTimeMillis();

    @Inject
    Vertx vertx;

    @ConfigProperty(name = "WATCHMAN")
    String _watchmanURL;

    @ConfigProperty(name = "SCORINGSERVICE")
    String _scoringServiceURL;

    @Funq
    @CloudEventMapping(responseType = "attackprocessed")
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

      System.out.println("Attack Event Received..." );

      // Watchman
      boolean watched = watchman.inform( "ATTACK:" + input );
      
      //Process the payload
      try
      {
        // Build a return packet
        MessageOutput output = new MessageOutput();

        JsonObject message = new JsonObject(input);

        String game = message.getString("game");
        String match = message.getString("match");
        boolean hit = message.getBoolean("hit");
        Long ts = message.getLong("ts");
        JsonObject by = message.getJsonObject("by");
        String uuid = by.getString("uuid");
        boolean human = by.getBoolean("human");
        Integer shotCount = by.getInteger("shotCount");
        Integer consecutiveHits = by.getInteger("consecutiveHitsCount");
        String destroyed = message.getString("destroyed");
  
        // Log for verbosity :-) 
        System.out.println( "  Game: " + game );
        System.out.println( "  Match: " + match );
        System.out.println( "  UUID: " + uuid );
        System.out.println( "  Hit: " + hit );
        System.out.println( "  TS: " + ts );
        System.out.println( "  Human: " + human );
        System.out.println( "  ShotCount: " + shotCount );
        System.out.println( "  ConsecutiveHits: " + consecutiveHits );
        System.out.println( "  Destroyed: " + destroyed );

        // PING INFINISPAN HERE

        // *If* we hit emit a score event for game server and scoring service
        if( hit )
        {
          // Calculate score delta
          int delta = 0;

          // If we haven't destroyed anything just increment the score
          if( destroyed == null )
          {
            delta = 1;
          }
          else
          {
            // Otherwise we destroyed something; use (type)[uppercased]_SCORE instead
            String targetShipENV = destroyed.toUpperCase() + "_SCORE";
            String envValue = System.getenv(targetShipENV);

            delta = ( envValue == null ? DEFAULT_DESTROYED_SCORE : Integer.parseInt(envValue) );
          }

          output.setGame(game);
          output.setMatch(match);
          output.setUuid(uuid);
          output.setTs(ts);
          output.setDelta(Integer.valueOf(delta));
          output.setHuman(human);

          // Post to Scoring Service
          String compositePostURL = _scoringServiceURL + "scoring/" + game + "/" + match + "/" + uuid + "?delta=" + delta + "&human=" + human + "&timestamp=" + ts;

          Postman postman = new Postman( compositePostURL );
          if( !( postman.deliver("dummy")))
          {
            System.out.println( "Failed to update Scoring Service");
          }

          emitter.complete(output);
        }
      }
      catch( Exception exc )
      {
        System.out.println("Failed to parse JSON due to " + exc.toString());
        return;
      }
    }
}
