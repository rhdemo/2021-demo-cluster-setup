package org.uth.summit.utils;

import java.net.*;

public class Postman 
{
  private String _target = null;

  public Postman( String targetURL )
  {
    _target = targetURL;
  }

  public boolean deliver( String optionalPayload )
  {
    try
    {
      //System.out.println( "Posting to " + _target );
      //System.out.println( "  (Optional Payload: " + optionalPayload + ")");

      URL url = new URL(_target);
      HttpURLConnection postConnection = (HttpURLConnection)url.openConnection();

      postConnection.setRequestMethod( "POST" );
      postConnection.setRequestProperty( "Content-Type", "application/json" );

      postConnection.setDoOutput(true);

      int responseCode = postConnection.getResponseCode();

      System.out.println( responseCode + " from " + _target );

      return true;
    }
    catch( Exception exc )
    {
      System.out.println( "Postman failure: " + exc.toString());

      return false;
    }
  }
}
