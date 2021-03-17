package functions;

      // {\"game\":\"BDP7pmbAAq_mvTPlAFAi4\",\"match\":\"DRSEcJb74dUQrFEredBZw\",\"playerA\":{\"username\":\"Root Knife\",\"uuid\":\"p28_Coyrl0GgcIlYATY4w\",\"human\":true,\"board


// POJO for emitted cloud event for Attack/Score
public class MessageOutput
{
  private String _game = null;
  private String _match = null;
  private String _Ausername = null;
  private String _Auuid = null;
  private boolean _Ahuman = false;
  private String _Busername = null;
  private String _Buuid = null;
  private boolean _Bhuman = false;
  
  // Setters
  public void setGame( String game ) { _game = game; }
  public void setMatch( String match ) { _match = match; }
  public void setAusername( String ausername ) { _Ausername = ausername; }
  public void setAuuid( String auuid ) { _Auuid = auuid; }
  public void setAhuman( boolean ahuman ) { _Ahuman = ahuman; }
  public void setBusername( String busername ) { _Busername = busername; }
  public void setBuuid( String buuid ) { _Buuid = buuid; }
  public void setBhuman( boolean bhuman ) { _Bhuman = bhuman; }
  
  // Accessors
  public String getGame() { return _game; }
  public String getMatch() { return _match; }
  public String getAusername() { return _Ausername; }
  public String getAuuid() { return _Auuid; }
  public boolean getAhuman() { return _Ahuman; }
  public String getBusername() { return _Busername; }
  public String getBuuid() { return _Buuid; }
  public boolean getBhuman() { return _Bhuman; }
}