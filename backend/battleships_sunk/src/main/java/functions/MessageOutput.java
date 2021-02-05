package functions;

public class MessageOutput
{
  private int _responseCode = 0;
  private String _name = null;
  private String _details = null;
  private long _elapsed = 0;

  // Setters
  public void setResponseCode( int value )
  {
    _responseCode = value;
  }

  public void setName( String name )
  {
    _name = name;
  }

  public void setDetails( String details )
  {
    _details = details;
  }

  public void setElapsed( long value )
  {
    _elapsed = value;
  }
  
  // Accessors
  public int getResponseCode() { return this._responseCode; }
  public String getName() { return this._name; }
  public String getDetails() { return this._details; }
  public long getElapsed() { return this._elapsed; }
}