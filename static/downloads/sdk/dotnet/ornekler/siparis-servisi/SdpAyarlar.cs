using System;
using StarDataParadise.SDK;

public static class SdpAyarlar
{
    public static string BaglantiMetni()
    {
        var b = SdpFactory.Instance.CreateConnectionStringBuilder();
        b["Host"] = "127.0.0.1";
        b["Port"] = 7443;
        b["TLS Name"] = "localhost";
        b["CA File"] = Zorunlu("SDP_CA");
        b["User"] = Zorunlu("SDP_USER");
        b["Password"] = Zorunlu("SDP_PASSWORD");
        b["Timeout"] = 15;
        b["Pooling"] = false;
        return b.ConnectionString;
    }

    private static string Zorunlu(string ad)
    {
        var deger = Environment.GetEnvironmentVariable(ad);
        return !string.IsNullOrEmpty(deger)
            ? deger : throw new InvalidOperationException("Eksik ayar: " + ad);
    }
}
