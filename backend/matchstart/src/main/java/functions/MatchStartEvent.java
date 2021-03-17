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

import java.time.LocalTime;
import javax.inject.Inject;
import java.net.*;
import java.util.*;

import org.uth.summit.utils.*;

public class MatchStartEvent 
{
    private long start = System.currentTimeMillis();

    @Inject
    Vertx vertx;

    @ConfigProperty(name = "WATCHMAN")
    String _watchmanURL;

    @ConfigProperty(name = "SCORINGSERVICE")
    String _scoringServiceURL;

    @Funq
    @CloudEventMapping(responseType = "matchstartprocessed")
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

      System.out.println("Match Start Event Received..." );
      System.out.println(input);

      //Process the payload
      try
      {
        // Build a return packet
        MessageOutput output = new MessageOutput();

        JsonObject message = new JsonObject(input);

        String game = message.getString("game");
        String match = message.getString("match");

        JsonObject playerA = message.getJsonObject("playerA");
        String playerAUsername = playerA.getString("username");
        String playerAUuid = playerA.getString("uuid");
        boolean playerAHuman = playerA.getBoolean("human");
        
        JsonObject playerB = message.getJsonObject("playerB");
        String playerBUsername = playerB.getString("username");
        String playerBUuid = playerB.getString("uuid");
        boolean playerBHuman = playerB.getBoolean("human");
        
        // Watchman
        LocalTime now = LocalTime.now();
        boolean watched = watchman.inform( "[MATCH-START] (" + now.toString() + ") " + playerAUsername + "(" + ( playerAHuman ? "HUME" : "BOTTY" ) + ") vs " + playerBUsername + "(" + ( playerBHuman ? "HUME" : "BOTTY" ) + ")");
      
        // Log for verbosity :-) 
        System.out.println( "  Game: " + game );
        System.out.println( "  Match: " + match );
        System.out.println( "  PlayerA:" );
        System.out.println( "    " + playerAUsername + " " + ( playerAHuman ? "(HUME)" : "(BOTTY)"));
        System.out.println( "  PlayerB:" );
        System.out.println( "    " + playerBUsername + " " + ( playerBHuman ? "(HUME)" : "(BOTTY)"));
        
        output.setGame(game);
        output.setMatch(match);
        output.setAusername(playerAUsername);
        output.setBusername(playerBUsername);
        output.setAhuman(playerAHuman);
        output.setBhuman(playerBHuman);

        emitter.complete(output);
      }
      catch( Exception exc )
      {
        System.out.println("Failed to parse JSON due to " + exc.toString());
        return;
      }
    }
}
