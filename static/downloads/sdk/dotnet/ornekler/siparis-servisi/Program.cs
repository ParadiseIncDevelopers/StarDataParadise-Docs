using System.Globalization;
using StarDataParadise.SDK;

if (args.Length != 4)
{
    Console.Error.WriteLine(
        "Kullanım: dotnet run -- <siparis-id> <musteri-id> <urun-id> <adet>");
    return 2;
}
if (!long.TryParse(args[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out var siparisId)
    || !long.TryParse(args[1], NumberStyles.Integer, CultureInfo.InvariantCulture, out var musteriId)
    || !long.TryParse(args[2], NumberStyles.Integer, CultureInfo.InvariantCulture, out var urunId)
    || !long.TryParse(args[3], NumberStyles.Integer, CultureInfo.InvariantCulture, out var adet))
{
    Console.Error.WriteLine("Argümanların tamamı signed 64 bit tamsayı olmalı.");
    return 2;
}

try
{
    Console.WriteLine(await SiparisServisi.OlusturAsync(siparisId, musteriId, urunId, adet));
    return 0;
}
catch (SdpException hata) when (hata.UnknownOutcome)
{
    Console.Error.WriteLine(
        $"status=unknown_outcome siparis_id={siparisId} request_token={Alan(hata.RequestToken)} " +
        $"code={hata.Code} sqlstate={Alan(hata.SqlState)} correlation_id={Alan(hata.CorrelationId)}");
    Console.Error.WriteLine("SQL yeniden gönderilmedi. Token ile yeni oturumdan sonucu sorgulayın.");
    Console.Error.Flush();
    return 7;
}
catch (SdpException hata)
{
    Console.Error.WriteLine(
        $"status=failed siparis_id={siparisId} code={hata.Code} sqlstate={Alan(hata.SqlState)} " +
        $"correlation_id={Alan(hata.CorrelationId)} reason={Alan(hata.Message)}");
    return 1;
}
catch (ArgumentException hata)
{
    Console.Error.WriteLine($"status=invalid_input reason={Alan(hata.Message)}");
    return 2;
}
catch (Exception hata)
{
    Console.Error.WriteLine($"status=failed siparis_id={siparisId} reason={Alan(hata.Message)}");
    return 1;
}

static string Alan(string? deger) =>
    deger?.Replace('\r', ' ').Replace('\n', ' ') ?? "<yok>";
