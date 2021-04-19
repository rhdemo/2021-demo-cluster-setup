package functions;

import io.quarkus.funqy.Context;
import io.quarkus.funqy.Funq;
import io.quarkus.funqy.knative.events.CloudEvent;
import io.quarkus.funqy.knative.events.CloudEventMapping;
import io.quarkus.funqy.knative.events.CloudEventBuilder;
import io.smallrye.mutiny.Uni;
import io.smallrye.mutiny.subscription.UniEmitter;
import io.vertx.core.Vertx;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.context.ManagedExecutor;

import io.vertx.core.json.JsonObject;
import io.vertx.core.json.Json;

import javax.inject.Inject;
import java.util.concurrent.*;
import java.io.*;
import java.net.*;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.text.*;

import org.uth.summit.utils.*;

public class BonusEventHttp 
{
    private static final int DEFAULT_BONUS_SCORE = 5;
    private long start = System.currentTimeMillis();

    @Inject
    ManagedExecutor executor;

    @ConfigProperty(name = "WATCHMAN")
    String _watchmanURL;

    @ConfigProperty(name = "SCORINGSERVICE")
    String _scoringServiceURL;

    @ConfigProperty(name = "PRODMODE")
    String _prodmode;

    @ConfigProperty(name = "NAMESPACE")
    String _namespace;

    @ConfigProperty(name = "BROKER")
    String _broker;

    @Funq
    public void processorHttp( String input )
    {
      executor.execute(() ->
      {
        try 
        {
          URL url = new URL("http://broker-ingress.knative-eventing.svc.cluster.local/" + _namespace + "/" + _broker);  
          
          MessageOutput output = buildResponse(input);
          String eventType = ( output.getHostname() == null ? "bonusprocessed" : "bonusprocessed-" + output.getHostname() );

          HttpURLConnection httpURLConnection = (HttpURLConnection)url.openConnection();
          httpURLConnection.setRequestMethod("POST");
          httpURLConnection.setRequestProperty("Content-Type", "application/json; utf-8");

          // Set the Cloud Event properties
          httpURLConnection.setRequestProperty("ce-type", eventType );
          httpURLConnection.setRequestProperty("ce-specversion", "1.0");
          httpURLConnection.setRequestProperty("ce-source", "attack");
          httpURLConnection.setRequestProperty("ce-partitionkey", output.getGame() + ":" + output.getMatch());

          httpURLConnection.setDoOutput(false);
          httpURLConnection.setDoInput(true);

          // Encode the created object into JSON
          String jsonOutput = Json.encode(output);

          OutputStream postedOutput = httpURLConnection.getOutputStream();
          byte[] payload = jsonOutput.getBytes("utf-8");
          postedOutput.write(payload, 0,  payload.length);
        } 
        catch( Exception exc ) 
        {
          System.out.println( "Post failed due to " + exc.toString());
        }
      });
    }

    //public CloudEvent<MessageOutput> processor( String input )  
    //{
    //  MessageOutput output = buildResponse( input );
    //  String eventName = ( output.getHostname() == null ? "bonusprocessed" : "bonusprocessed-" + output.getHostname() );

    //  return CloudEventBuilder.create()
    //    .extensions(Map.of("partitionkey", output.getGame() + ":" + output.getMatch()))
    //    .type(eventName)
    //    .build(output);      
    //}

    public MessageOutput buildResponse( String input )
    {
      // Setup Watchman
      Watchman watchman = new Watchman( _watchmanURL );

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
        String hostname = message.getString("hostname");
        Long ts = message.getLong("ts");
        boolean human = by.getBoolean("human");
        String username = by.getString("username");
        Integer shots = message.getInteger("shots");
  
        // Watchman
        if( _prodmode.equals("dev"))
        {
          LocalDateTime now = LocalDateTime.now();

          boolean watched = watchman.inform( "[BONUS] (" + now.toString() +"):" + match + " game:" + game + " uuid: " + uuid + " name: " + username + ( shots != null ? " shots:" + shots.toString() : "" ));

          // Log for verbosity :-) 
          System.out.println( "  Game: " + game );
          System.out.println( "  Match: " + match );
          System.out.println( "  UUID: " + uuid );
          System.out.println( "  Username: " + username );
          System.out.println( "  Human: " + human );
        }

        String envValue = System.getenv("BONUS_SCORE");
        int delta = 0;
        int multiplier = ( envValue == null ? DEFAULT_BONUS_SCORE : Integer.parseInt(envValue));
        delta = ( shots == null ? multiplier : ( shots * multiplier));

        output.setGame(game);
        output.setMatch(match);
        output.setUuid(uuid);
        output.setHostname(hostname);
        output.setTs(ts);
        output.setDelta(Integer.valueOf(delta));
        output.setHuman(human);

        // Convert spaces in the username for URL
        username = username.replaceAll(" ", "%20");

        // Post to Scoring Service
        String compositePostURL = _scoringServiceURL + "scoring/" + game + "/" + match + "/" + uuid + "?delta=" + delta + "&human=" + human + "&username" + username + "&timestamp=" + ts + "&bonus=true";

        Postman postman = new Postman( compositePostURL );
        if( !( postman.deliver("dummy")))
        {
          System.out.println( "Failed to update Scoring Service");
        }

        return output;
      }
      catch( Exception exc )
      {
        System.out.println("Failed to parse JSON due to " + exc.toString());
        return null;  
      }
    }
}
