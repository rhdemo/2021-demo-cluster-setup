package org.uth.summit.utils;

import java.net.*;

public class Watchman 
{
  private String _watchmanURL = null;

  public Watchman( String targetURL )
  {
    _watchmanURL = targetURL;
  }

  private boolean inform( String output )
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
