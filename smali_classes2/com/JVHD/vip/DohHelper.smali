.class public final Lcom/JVHD/vip/DohHelper;
.super Ljava/lang/Object;
.source "DohHelper.java"


# static fields
.field private static final MAX_REDIRECTS:I = 0x6


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 31
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method private static fetchWithRedirects(Ljava/net/URL;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)Lcom/JVHD/vip/MediaProxyServer$Upstream;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    const/4 v0, 0x6

    if-ge p4, v0, :cond_5

    .line 53
    invoke-static {p0, p1, p2, p3}, Lcom/JVHD/vip/RawHttp;->get(Ljava/net/URL;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Lcom/JVHD/vip/RawResponse;

    move-result-object v0

    .line 54
    iget v1, v0, Lcom/JVHD/vip/RawResponse;->code:I

    const/16 v2, 0x12d

    if-eq v1, v2, :cond_1

    const/16 v2, 0x12e

    if-eq v1, v2, :cond_1

    const/16 v2, 0x12f

    if-eq v1, v2, :cond_1

    const/16 v2, 0x133

    if-eq v1, v2, :cond_1

    const/16 v2, 0x134

    if-ne v1, v2, :cond_0

    goto :goto_0

    .line 65
    :cond_0
    new-instance p1, Lcom/JVHD/vip/MediaProxyServer$Upstream;

    new-instance p2, Lcom/JVHD/vip/FakeHttpURLConnection;

    invoke-direct {p2, p0, v0}, Lcom/JVHD/vip/FakeHttpURLConnection;-><init>(Ljava/net/URL;Lcom/JVHD/vip/RawResponse;)V

    invoke-virtual {p0}, Ljava/net/URL;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-direct {p1, p2, v1, p0}, Lcom/JVHD/vip/MediaProxyServer$Upstream;-><init>(Ljava/net/HttpURLConnection;ILjava/lang/String;)V

    return-object p1

    :cond_1
    :goto_0
    const-string v2, "Location"

    .line 56
    invoke-virtual {v0, v2}, Lcom/JVHD/vip/RawResponse;->header(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    if-eqz v2, :cond_4

    .line 57
    invoke-virtual {v2}, Ljava/lang/String;->length()I

    move-result v3

    if-nez v3, :cond_2

    goto :goto_1

    .line 60
    :cond_2
    invoke-virtual {v0}, Lcom/JVHD/vip/RawResponse;->close()V

    .line 61
    new-instance v0, Ljava/net/URL;

    invoke-direct {v0, p0, v2}, Ljava/net/URL;-><init>(Ljava/net/URL;Ljava/lang/String;)V

    .line 62
    invoke-virtual {v0}, Ljava/net/URL;->getProtocol()Ljava/lang/String;

    move-result-object p0

    sget-object v1, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {p0, v1}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    const-string v1, "https"

    invoke-virtual {v1, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_3

    add-int/lit8 p4, p4, 0x1

    .line 63
    invoke-static {v0, p1, p2, p3, p4}, Lcom/JVHD/vip/DohHelper;->fetchWithRedirects(Ljava/net/URL;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)Lcom/JVHD/vip/MediaProxyServer$Upstream;

    move-result-object p0

    return-object p0

    .line 62
    :cond_3
    new-instance p0, Ljava/io/IOException;

    const-string p1, "insecure redirect"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 58
    :cond_4
    :goto_1
    new-instance p1, Lcom/JVHD/vip/MediaProxyServer$Upstream;

    new-instance p2, Lcom/JVHD/vip/FakeHttpURLConnection;

    invoke-direct {p2, p0, v0}, Lcom/JVHD/vip/FakeHttpURLConnection;-><init>(Ljava/net/URL;Lcom/JVHD/vip/RawResponse;)V

    invoke-virtual {p0}, Ljava/net/URL;->toString()Ljava/lang/String;

    move-result-object p0

    invoke-direct {p1, p2, v1, p0}, Lcom/JVHD/vip/MediaProxyServer$Upstream;-><init>(Ljava/net/HttpURLConnection;ILjava/lang/String;)V

    return-object p1

    .line 52
    :cond_5
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Too many redirects"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method

.method public static tryFetch(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Lcom/JVHD/vip/MediaProxyServer$Upstream;
    .locals 4

    const/4 v0, 0x0

    if-eqz p0, :cond_6

    .line 37
    :try_start_0
    invoke-static {}, Lcom/JVHD/vip/Doh;->supportAvailable()Z

    move-result v1

    if-nez v1, :cond_0

    goto :goto_0

    .line 38
    :cond_0
    new-instance v1, Ljava/net/URL;

    invoke-direct {v1, p0}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    const-string p0, "https"

    .line 39
    invoke-virtual {v1}, Ljava/net/URL;->getProtocol()Ljava/lang/String;

    move-result-object v2

    sget-object v3, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {v2, v3}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v2

    invoke-virtual {p0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-nez p0, :cond_1

    return-object v0

    .line 40
    :cond_1
    invoke-virtual {v1}, Ljava/net/URL;->getHost()Ljava/lang/String;

    move-result-object p0

    if-eqz p0, :cond_6

    .line 41
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v2

    if-nez v2, :cond_2

    goto :goto_0

    :cond_2
    const-string v2, "127.0.0.1"

    .line 42
    invoke-virtual {p0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-nez v2, :cond_6

    const-string v2, "localhost"

    invoke-virtual {p0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_3

    goto :goto_0

    .line 43
    :cond_3
    invoke-static {p0}, Lcom/JVHD/vip/Doh;->isIpLiteral(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_4

    return-object v0

    .line 44
    :cond_4
    invoke-static {p0}, Lcom/JVHD/vip/Doh;->resolve(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    if-nez p0, :cond_5

    return-object v0

    :cond_5
    const/4 p0, 0x0

    .line 45
    invoke-static {v1, p1, p2, p3, p0}, Lcom/JVHD/vip/DohHelper;->fetchWithRedirects(Ljava/net/URL;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;I)Lcom/JVHD/vip/MediaProxyServer$Upstream;

    move-result-object p0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return-object p0

    :catchall_0
    :cond_6
    :goto_0
    return-object v0
.end method
