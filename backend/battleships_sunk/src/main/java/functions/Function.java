package functions;

import io.quarkus.funqy.Context;
import io.quarkus.funqy.Funq;
import io.quarkus.funqy.knative.events.CloudEvent;
import io.quarkus.funqy.knative.events.CloudEventMapping;
import io.smallrye.mutiny.Uni;
import io.smallrye.mutiny.subscription.UniEmitter;
import io.vertx.core.Vertx;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import javax.inject.Inject;
import java.net.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

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
      boolean watched = watchman( "SUNK:" + input );
      
      // Build a return packet
      MessageOutput output = new MessageOutput();

      output.setElapsed(System.currentTimeMillis() - start );
      output.setName("Payload Check");
      output.setDetails(input);
      output.setResponseCode(200);

      emitter.complete(output);
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
