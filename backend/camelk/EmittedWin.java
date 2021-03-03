// camel-k: language=java
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.*;

public class EmittedWin extends org.apache.camel.builder.RouteBuilder
{
  @Override
  public void configure() throws Exception
  {

    from("knative:event/winprocessed")
          .log("Received: ${body}");
  }
}
