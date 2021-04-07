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
import java.time.LocalDateTime;
import java.util.*;

import org.uth.summit.utils.*;

public class BonusEvent 
{
    private static final int DEFAULT_BONUS_SCORE = 5;
    private long start = System.currentTimeMillis();

    @Inject
    Vertx vertx;

    @ConfigProperty(name = "WATCHMAN")
    String _watchmanURL;

    @ConfigProperty(name = "SCORINGSERVICE")
    String _scoringServiceURL;

    @ConfigProperty(name = "PRODMODE")
    String _prodmode;

    @Funq
    @CloudEventMapping(responseType = "bonusprocessed")
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

      System.out.println("Bonus Event Received..." );

      //Process the payload
      try
      {
        // Build a return packet
        MessageOutput output = new MessageOutput();

        JsonObject message = new JsonObject(input);

        String game = message.getString("game");
        String match = message.getString("match");
        JsonObject by = message.getJsonObject("by");
        String uuid = by.getString("uuid");
        Long ts = message.getLong("ts");
        boolean human = by.getBoolean("human");
        String username = by.getString("username");
        Integer shots = message.getInteger("shots");
  
        // Watchman
        if( _prodmode.equals("dev"))
        {
          LocalDateTime now = LocalDateTime.now();

          boolean watched = watchman.inform( "[BONUS] (" + now.toString() +"):" + match + " game:" + game + " uuid: " + uuid + " name: " + username + ( shots != null ? " shots:" + shots.toString() : "" ));
        }

        // Log for verbosity :-) 
        System.out.println( "  Game: " + game );
        System.out.println( "  Match: " + match );
        System.out.println( "  UUID: " + uuid );
        System.out.println( "  Username: " + username );
        System.out.println( "  Human: " + human );

        String envValue = System.getenv("BONUS_SCORE");
        int delta = 0;
        int multiplier = ( envValue == null ? DEFAULT_BONUS_SCORE : Integer.parseInt(envValue));
        delta = ( shots == null ? multiplier : ( shots * multiplier));

        if( shots != null )
        {
          System.out.println( "  Shots (multiple):" + shots.toString());
        }
        else
        {
          System.out.println( "  Single Bonus Shot." );
          delta = 1;
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

          // Post hit to SHOTS scoring-service

          emitter.complete(output);
        }
        catch( Exception exc )
        {
          System.out.println("Failed to parse JSON due to " + exc.toString());
          return;  
        }
    }
}
