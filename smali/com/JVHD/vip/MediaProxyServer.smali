.class public final Lcom/JVHD/vip/MediaProxyServer;
.super Ljava/lang/Object;
.source "MediaProxyServer.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lcom/JVHD/vip/MediaProxyServer$Upstream;,
        Lcom/JVHD/vip/MediaProxyServer$Entry;
    }
.end annotation


# static fields
.field private static final CONNECT_TIMEOUT_MS:I = 0x2ee0

.field private static final ENTRY_TTL_MS:J = 0x1499700L

.field private static final HLS_URI:Ljava/util/regex/Pattern;

.field private static final MAX_PLAYLIST_BYTES:I = 0x800000

.field private static final MAX_WRAPPED_SEGMENT_BYTES:I = 0x2000000

.field private static final READ_TIMEOUT_MS:I = 0x4e20

.field private static final USER_AGENT:Ljava/lang/String; = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

.field private static volatile instance:Lcom/JVHD/vip/MediaProxyServer;


# instance fields
.field private final entries:Ljava/util/concurrent/ConcurrentHashMap;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/concurrent/ConcurrentHashMap<",
            "Ljava/lang/String;",
            "Lcom/JVHD/vip/MediaProxyServer$Entry;",
            ">;"
        }
    .end annotation
.end field

.field private final port:I

.field private final reverseEntries:Ljava/util/concurrent/ConcurrentHashMap;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/concurrent/ConcurrentHashMap<",
            "Ljava/lang/String;",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation
.end field

.field private final server:Ljava/net/ServerSocket;


# direct methods
.method static constructor <clinit>()V
    .locals 2

    const-string v0, "URI=(\\\"([^\\\"]+)\\\"|\'([^\']+)\')"

    const/4 v1, 0x2

    .line 43
    invoke-static {v0, v1}, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;I)Ljava/util/regex/Pattern;

    move-result-object v0

    sput-object v0, Lcom/JVHD/vip/MediaProxyServer;->HLS_URI:Ljava/util/regex/Pattern;

    return-void
.end method

.method private constructor <init>()V
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 52
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 49
    new-instance v0, Ljava/util/concurrent/ConcurrentHashMap;

    invoke-direct {v0}, Ljava/util/concurrent/ConcurrentHashMap;-><init>()V

    iput-object v0, p0, Lcom/JVHD/vip/MediaProxyServer;->entries:Ljava/util/concurrent/ConcurrentHashMap;

    .line 50
    new-instance v0, Ljava/util/concurrent/ConcurrentHashMap;

    invoke-direct {v0}, Ljava/util/concurrent/ConcurrentHashMap;-><init>()V

    iput-object v0, p0, Lcom/JVHD/vip/MediaProxyServer;->reverseEntries:Ljava/util/concurrent/ConcurrentHashMap;

    .line 53
    new-instance v0, Ljava/net/ServerSocket;

    const-string v1, "127.0.0.1"

    invoke-static {v1}, Ljava/net/InetAddress;->getByName(Ljava/lang/String;)Ljava/net/InetAddress;

    move-result-object v1

    const/4 v2, 0x0

    const/16 v3, 0x32

    invoke-direct {v0, v2, v3, v1}, Ljava/net/ServerSocket;-><init>(IILjava/net/InetAddress;)V

    iput-object v0, p0, Lcom/JVHD/vip/MediaProxyServer;->server:Ljava/net/ServerSocket;

    const/4 v1, 0x1

    .line 54
    invoke-virtual {v0, v1}, Ljava/net/ServerSocket;->setReuseAddress(Z)V

    .line 55
    invoke-virtual {v0}, Ljava/net/ServerSocket;->getLocalPort()I

    move-result v0

    iput v0, p0, Lcom/JVHD/vip/MediaProxyServer;->port:I

    .line 56
    new-instance v0, Ljava/lang/Thread;

    new-instance v2, Lcom/JVHD/vip/MediaProxyServer$1;

    invoke-direct {v2, p0}, Lcom/JVHD/vip/MediaProxyServer$1;-><init>(Lcom/JVHD/vip/MediaProxyServer;)V

    const-string v3, "BinTV-JVHD-Proxy"

    invoke-direct {v0, v2, v3}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 59
    invoke-virtual {v0, v1}, Ljava/lang/Thread;->setDaemon(Z)V

    .line 60
    invoke-virtual {v0}, Ljava/lang/Thread;->start()V

    return-void
.end method

.method private acceptLoop()V
    .locals 3

    .line 138
    :cond_0
    :goto_0
    iget-object v0, p0, Lcom/JVHD/vip/MediaProxyServer;->server:Ljava/net/ServerSocket;

    invoke-virtual {v0}, Ljava/net/ServerSocket;->isClosed()Z

    move-result v0

    if-nez v0, :cond_1

    .line 140
    :try_start_0
    iget-object v0, p0, Lcom/JVHD/vip/MediaProxyServer;->server:Ljava/net/ServerSocket;

    invoke-virtual {v0}, Ljava/net/ServerSocket;->accept()Ljava/net/Socket;

    move-result-object v0

    const/16 v1, 0x4e20

    .line 141
    invoke-virtual {v0, v1}, Ljava/net/Socket;->setSoTimeout(I)V

    .line 142
    new-instance v1, Ljava/lang/Thread;

    new-instance v2, Lcom/JVHD/vip/MediaProxyServer$2;

    invoke-direct {v2, p0, v0}, Lcom/JVHD/vip/MediaProxyServer$2;-><init>(Lcom/JVHD/vip/MediaProxyServer;Ljava/net/Socket;)V

    const-string v0, "BinTV-JVHD-Media"

    invoke-direct {v1, v2, v0}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    const/4 v0, 0x1

    .line 145
    invoke-virtual {v1, v0}, Ljava/lang/Thread;->setDaemon(Z)V

    .line 146
    invoke-virtual {v1}, Ljava/lang/Thread;->start()V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    nop

    .line 148
    iget-object v0, p0, Lcom/JVHD/vip/MediaProxyServer;->server:Ljava/net/ServerSocket;

    invoke-virtual {v0}, Ljava/net/ServerSocket;->isClosed()Z

    move-result v0

    if-nez v0, :cond_0

    const-wide/16 v0, 0x64

    .line 149
    :try_start_1
    invoke-static {v0, v1}, Ljava/lang/Thread;->sleep(J)V
    :try_end_1
    .catch Ljava/lang/InterruptedException; {:try_start_1 .. :try_end_1} :catch_1

    goto :goto_0

    :catch_1
    invoke-static {}, Ljava/lang/Thread;->currentThread()Ljava/lang/Thread;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/Thread;->interrupt()V

    goto :goto_0

    :cond_1
    return-void
.end method

.method static synthetic access$000(Lcom/JVHD/vip/MediaProxyServer;)V
    .locals 0

    .line 34
    invoke-direct {p0}, Lcom/JVHD/vip/MediaProxyServer;->acceptLoop()V

    return-void
.end method

.method static synthetic access$100(Lcom/JVHD/vip/MediaProxyServer;Ljava/net/Socket;)V
    .locals 0

    .line 34
    invoke-direct {p0, p1}, Lcom/JVHD/vip/MediaProxyServer;->handleQuietly(Ljava/net/Socket;)V

    return-void
.end method

.method private cleanupIfNeeded()V
    .locals 7

    .line 125
    iget-object v0, p0, Lcom/JVHD/vip/MediaProxyServer;->entries:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {v0}, Ljava/util/concurrent/ConcurrentHashMap;->size()I

    move-result v0

    const/16 v1, 0x1000

    if-ge v0, v1, :cond_0

    return-void

    .line 126
    :cond_0
    invoke-static {}, Ljava/lang/System;->currentTimeMillis()J

    move-result-wide v0

    const-wide/32 v2, 0x1499700

    sub-long/2addr v0, v2

    .line 127
    iget-object v2, p0, Lcom/JVHD/vip/MediaProxyServer;->entries:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {v2}, Ljava/util/concurrent/ConcurrentHashMap;->entrySet()Ljava/util/Set;

    move-result-object v2

    invoke-interface {v2}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    move-result-object v2

    .line 128
    :cond_1
    :goto_0
    invoke-interface {v2}, Ljava/util/Iterator;->hasNext()Z

    move-result v3

    if-eqz v3, :cond_2

    .line 129
    invoke-interface {v2}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ljava/util/Map$Entry;

    .line 130
    invoke-interface {v3}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Lcom/JVHD/vip/MediaProxyServer$Entry;

    iget-wide v4, v4, Lcom/JVHD/vip/MediaProxyServer$Entry;->createdAt:J

    cmp-long v6, v4, v0

    if-gez v6, :cond_1

    .line 131
    iget-object v4, p0, Lcom/JVHD/vip/MediaProxyServer;->entries:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-interface {v3}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    move-result-object v5

    invoke-virtual {v4, v5}, Ljava/util/concurrent/ConcurrentHashMap;->remove(Ljava/lang/Object;)Ljava/lang/Object;

    .line 132
    iget-object v4, p0, Lcom/JVHD/vip/MediaProxyServer;->reverseEntries:Ljava/util/concurrent/ConcurrentHashMap;

    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    invoke-interface {v3}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    move-result-object v6

    check-cast v6, Lcom/JVHD/vip/MediaProxyServer$Entry;

    iget-object v6, v6, Lcom/JVHD/vip/MediaProxyServer$Entry;->url:Ljava/lang/String;

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    const-string v6, "\n"

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-interface {v3}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Lcom/JVHD/vip/MediaProxyServer$Entry;

    iget-object v3, v3, Lcom/JVHD/vip/MediaProxyServer$Entry;->referer:Ljava/lang/String;

    invoke-virtual {v5, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v4, v3}, Ljava/util/concurrent/ConcurrentHashMap;->remove(Ljava/lang/Object;)Ljava/lang/Object;

    goto :goto_0

    :cond_2
    return-void
.end method

.method private static copy(Ljava/io/InputStream;Ljava/io/OutputStream;)V
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    const/high16 v0, 0x10000

    new-array v0, v0, [B

    .line 331
    :goto_0
    invoke-virtual {p0, v0}, Ljava/io/InputStream;->read([B)I

    move-result v1

    const/4 v2, -0x1

    if-eq v1, v2, :cond_0

    const/4 v2, 0x0

    invoke-virtual {p1, v0, v2, v1}, Ljava/io/OutputStream;->write([BII)V

    goto :goto_0

    :cond_0
    return-void
.end method

.method private static copyHeader(Ljava/net/HttpURLConnection;Ljava/util/Map;Ljava/lang/String;)V
    .locals 2
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/net/HttpURLConnection;",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Ljava/lang/String;",
            ">;",
            "Ljava/lang/String;",
            ")V"
        }
    .end annotation

    .line 335
    invoke-virtual {p0, p2}, Ljava/net/HttpURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    if-eqz p0, :cond_0

    .line 336
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    if-lez v0, :cond_0

    const-string v0, "\r"

    const-string v1, ""

    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p0

    const-string v0, "\n"

    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p0

    invoke-interface {p1, p2, p0}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    :cond_0
    return-void
.end method

.method public static createProxyUrl(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 65
    invoke-static {p0}, Lcom/JVHD/vip/MediaProxyServer;->isHttpUrl(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_1

    if-nez p0, :cond_0

    const-string p0, ""

    :cond_0
    return-object p0

    .line 67
    :cond_1
    :try_start_0
    sget-object v0, Lcom/JVHD/vip/MediaProxyServer;->instance:Lcom/JVHD/vip/MediaProxyServer;

    if-nez v0, :cond_3

    .line 69
    const-class v0, Lcom/JVHD/vip/MediaProxyServer;

    monitor-enter v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 70
    :try_start_1
    sget-object v1, Lcom/JVHD/vip/MediaProxyServer;->instance:Lcom/JVHD/vip/MediaProxyServer;

    if-nez v1, :cond_2

    .line 72
    new-instance v1, Lcom/JVHD/vip/MediaProxyServer;

    invoke-direct {v1}, Lcom/JVHD/vip/MediaProxyServer;-><init>()V

    .line 73
    sput-object v1, Lcom/JVHD/vip/MediaProxyServer;->instance:Lcom/JVHD/vip/MediaProxyServer;

    .line 75
    :cond_2
    monitor-exit v0

    move-object v0, v1

    goto :goto_0

    :catchall_0
    move-exception p1

    monitor-exit v0
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    :try_start_2
    throw p1

    .line 77
    :cond_3
    :goto_0
    invoke-static {p1}, Lcom/JVHD/vip/MediaProxyServer;->sanitizeReferer(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    invoke-direct {v0, p0, p1}, Lcom/JVHD/vip/MediaProxyServer;->register(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    :catchall_1
    return-object p0
.end method

.method private static findFragmentedMp4Offset([B)I
    .locals 8

    .line 413
    array-length v0, p0

    add-int/lit8 v0, v0, -0x8

    const/16 v1, 0x1000

    invoke-static {v1, v0}, Ljava/lang/Math;->min(II)I

    move-result v0

    const/4 v1, 0x4

    const/4 v2, 0x4

    :goto_0
    if-gt v2, v0, :cond_2

    .line 415
    aget-byte v3, p0, v2

    const/16 v4, 0x66

    const/16 v5, 0x70

    const/16 v6, 0x79

    const/16 v7, 0x74

    if-ne v3, v4, :cond_0

    add-int/lit8 v4, v2, 0x1

    aget-byte v4, p0, v4

    if-ne v4, v7, :cond_0

    add-int/lit8 v4, v2, 0x2

    aget-byte v4, p0, v4

    if-ne v4, v6, :cond_0

    add-int/lit8 v4, v2, 0x3

    aget-byte v4, p0, v4

    if-ne v4, v5, :cond_0

    sub-int/2addr v2, v1

    return v2

    :cond_0
    const/16 v4, 0x73

    if-ne v3, v4, :cond_1

    add-int/lit8 v3, v2, 0x1

    .line 416
    aget-byte v3, p0, v3

    if-ne v3, v7, :cond_1

    add-int/lit8 v3, v2, 0x2

    aget-byte v3, p0, v3

    if-ne v3, v6, :cond_1

    add-int/lit8 v3, v2, 0x3

    aget-byte v3, p0, v3

    if-ne v3, v5, :cond_1

    sub-int/2addr v2, v1

    return v2

    :cond_1
    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    :cond_2
    const/4 p0, -0x1

    return p0
.end method

.method private static findTransportStreamOffset([B)I
    .locals 7

    .line 400
    array-length v0, p0

    add-int/lit16 v0, v0, -0x3ac

    const/16 v1, 0x1000

    invoke-static {v1, v0}, Ljava/lang/Math;->min(II)I

    move-result v0

    const/4 v1, 0x0

    const/4 v2, 0x0

    :goto_0
    if-gt v2, v0, :cond_4

    .line 402
    aget-byte v3, p0, v2

    and-int/lit16 v3, v3, 0xff

    const/16 v4, 0x47

    if-eq v3, v4, :cond_0

    goto :goto_3

    :cond_0
    const/4 v3, 0x1

    const/4 v5, 0x1

    :goto_1
    const/4 v6, 0x5

    if-ge v5, v6, :cond_2

    mul-int/lit16 v6, v5, 0xbc

    add-int/2addr v6, v2

    .line 405
    aget-byte v6, p0, v6

    and-int/lit16 v6, v6, 0xff

    if-eq v6, v4, :cond_1

    const/4 v3, 0x0

    goto :goto_2

    :cond_1
    add-int/lit8 v5, v5, 0x1

    goto :goto_1

    :cond_2
    :goto_2
    if-eqz v3, :cond_3

    return v2

    :cond_3
    :goto_3
    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    :cond_4
    const/4 p0, -0x1

    return p0
.end method

.method private handle(Ljava/net/Socket;)V
    .locals 12
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 165
    new-instance v0, Ljava/io/BufferedReader;

    new-instance v1, Ljava/io/InputStreamReader;

    new-instance v2, Ljava/io/BufferedInputStream;

    invoke-virtual {p1}, Ljava/net/Socket;->getInputStream()Ljava/io/InputStream;

    move-result-object v3

    invoke-direct {v2, v3}, Ljava/io/BufferedInputStream;-><init>(Ljava/io/InputStream;)V

    sget-object v3, Ljava/nio/charset/StandardCharsets;->ISO_8859_1:Ljava/nio/charset/Charset;

    invoke-direct {v1, v2, v3}, Ljava/io/InputStreamReader;-><init>(Ljava/io/InputStream;Ljava/nio/charset/Charset;)V

    invoke-direct {v0, v1}, Ljava/io/BufferedReader;-><init>(Ljava/io/Reader;)V

    .line 166
    invoke-virtual {v0}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;

    move-result-object v1

    const-string v2, "Bad request"

    const/16 v3, 0x190

    const-string v4, "text/plain"

    if-eqz v1, :cond_b

    .line 167
    invoke-virtual {v1}, Ljava/lang/String;->length()I

    move-result v5

    const/16 v6, 0x2000

    if-le v5, v6, :cond_0

    goto/16 :goto_1

    :cond_0
    const-string v5, " "

    .line 168
    invoke-virtual {v1, v5}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v1

    .line 169
    array-length v5, v1

    const/4 v6, 0x2

    if-ge v5, v6, :cond_1

    invoke-static {p1, v3, v4, v2}, Lcom/JVHD/vip/MediaProxyServer;->sendSmallResponse(Ljava/net/Socket;ILjava/lang/String;Ljava/lang/String;)V

    return-void

    :cond_1
    const/4 v2, 0x0

    .line 170
    aget-object v3, v1, v2

    sget-object v5, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {v3, v5}, Ljava/lang/String;->toUpperCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v3

    const/4 v5, 0x1

    .line 171
    aget-object v1, v1, v5

    .line 172
    new-instance v5, Ljava/util/HashMap;

    invoke-direct {v5}, Ljava/util/HashMap;-><init>()V

    const/4 v6, 0x0

    .line 175
    :cond_2
    :goto_0
    invoke-virtual {v0}, Ljava/io/BufferedReader;->readLine()Ljava/lang/String;

    move-result-object v7

    if-eqz v7, :cond_4

    invoke-virtual {v7}, Ljava/lang/String;->length()I

    move-result v8

    if-lez v8, :cond_4

    .line 176
    invoke-virtual {v7}, Ljava/lang/String;->length()I

    move-result v8

    add-int/2addr v6, v8

    const/high16 v8, 0x10000

    if-le v6, v8, :cond_3

    const/16 v0, 0x1af

    const-string v1, "Headers too large"

    .line 177
    invoke-static {p1, v0, v4, v1}, Lcom/JVHD/vip/MediaProxyServer;->sendSmallResponse(Ljava/net/Socket;ILjava/lang/String;Ljava/lang/String;)V

    return-void

    :cond_3
    const/16 v8, 0x3a

    .line 178
    invoke-virtual {v7, v8}, Ljava/lang/String;->indexOf(I)I

    move-result v8

    if-lez v8, :cond_2

    .line 179
    invoke-virtual {v7, v2, v8}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v9

    invoke-virtual {v9}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v9

    sget-object v10, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {v9, v10}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v9

    add-int/lit8 v8, v8, 0x1

    invoke-virtual {v7, v8}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v7

    invoke-virtual {v7}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v7

    invoke-interface {v5, v9, v7}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    goto :goto_0

    :cond_4
    const-string v0, "OPTIONS"

    .line 181
    invoke-virtual {v0, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_5

    invoke-virtual {p1}, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v6

    const/16 v7, 0xcc

    const-wide/16 v9, 0x0

    const/4 v11, 0x0

    const-string v8, "text/plain"

    invoke-static/range {v6 .. v11}, Lcom/JVHD/vip/MediaProxyServer;->sendHeaders(Ljava/io/OutputStream;ILjava/lang/String;JLjava/util/Map;)V

    return-void

    :cond_5
    const-string v0, "GET"

    .line 182
    invoke-virtual {v0, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_6

    const-string v0, "HEAD"

    invoke-virtual {v0, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_6

    const/16 v0, 0x195

    const-string v1, "Method not allowed"

    invoke-static {p1, v0, v4, v1}, Lcom/JVHD/vip/MediaProxyServer;->sendSmallResponse(Ljava/net/Socket;ILjava/lang/String;Ljava/lang/String;)V

    return-void

    :cond_6
    const-string v0, "/jvhd-media/"

    .line 184
    invoke-virtual {v1, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v0

    const/16 v6, 0x194

    if-nez v0, :cond_7

    const-string v0, "Not found"

    invoke-static {p1, v6, v4, v0}, Lcom/JVHD/vip/MediaProxyServer;->sendSmallResponse(Ljava/net/Socket;ILjava/lang/String;Ljava/lang/String;)V

    return-void

    :cond_7
    const/16 v0, 0xc

    .line 185
    invoke-virtual {v1, v0}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v0

    const/16 v1, 0x2f

    .line 186
    invoke-virtual {v0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-ltz v1, :cond_8

    .line 187
    invoke-virtual {v0, v2, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v0

    :cond_8
    const/16 v1, 0x3f

    .line 188
    invoke-virtual {v0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-ltz v1, :cond_9

    .line 189
    invoke-virtual {v0, v2, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v0

    .line 190
    :cond_9
    iget-object v1, p0, Lcom/JVHD/vip/MediaProxyServer;->entries:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {v1, v0}, Ljava/util/concurrent/ConcurrentHashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Lcom/JVHD/vip/MediaProxyServer$Entry;

    if-nez v0, :cond_a

    const-string v0, "Expired media token"

    .line 191
    invoke-static {p1, v6, v4, v0}, Lcom/JVHD/vip/MediaProxyServer;->sendSmallResponse(Ljava/net/Socket;ILjava/lang/String;Ljava/lang/String;)V

    return-void

    .line 192
    :cond_a
    invoke-direct {p0, p1, v3, v5, v0}, Lcom/JVHD/vip/MediaProxyServer;->proxy(Ljava/net/Socket;Ljava/lang/String;Ljava/util/Map;Lcom/JVHD/vip/MediaProxyServer$Entry;)V

    return-void

    .line 167
    :cond_b
    :goto_1
    invoke-static {p1, v3, v4, v2}, Lcom/JVHD/vip/MediaProxyServer;->sendSmallResponse(Ljava/net/Socket;ILjava/lang/String;Ljava/lang/String;)V

    return-void
.end method

.method private handleQuietly(Ljava/net/Socket;)V
    .locals 3

    .line 156
    :try_start_0
    invoke-direct {p0, p1}, Lcom/JVHD/vip/MediaProxyServer;->handle(Ljava/net/Socket;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 160
    :catchall_0
    :goto_0
    :try_start_1
    invoke-virtual {p1}, Ljava/net/Socket;->close()V
    :try_end_1
    .catch Ljava/io/IOException; {:try_start_1 .. :try_end_1} :catch_0

    goto :goto_1

    :catchall_1
    const/16 v0, 0x1f6

    :try_start_2
    const-string v1, "text/plain; charset=utf-8"

    const-string v2, "Media proxy error"

    .line 158
    invoke-static {p1, v0, v1, v2}, Lcom/JVHD/vip/MediaProxyServer;->sendSmallResponse(Ljava/net/Socket;ILjava/lang/String;Ljava/lang/String;)V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    goto :goto_0

    :catch_0
    :goto_1
    return-void
.end method

.method private static isHttpUrl(Ljava/lang/String;)Z
    .locals 2

    const/4 v0, 0x0

    if-nez p0, :cond_0

    return v0

    .line 86
    :cond_0
    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    sget-object v1, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {p0, v1}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    const-string v1, "http://"

    .line 87
    invoke-virtual {p0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_1

    const-string v1, "https://"

    invoke-virtual {p0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_2

    :cond_1
    const/4 v0, 0x1

    :cond_2
    return v0
.end method

.method private static isPlaylistUrl(Ljava/lang/String;)Z
    .locals 2

    const/4 v0, 0x0

    if-nez p0, :cond_0

    return v0

    .line 383
    :cond_0
    sget-object v1, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {p0, v1}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    const/16 v1, 0x23

    .line 384
    invoke-virtual {p0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-ltz v1, :cond_1

    .line 385
    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    :cond_1
    const/16 v1, 0x3f

    .line 386
    invoke-virtual {p0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-ltz v1, :cond_2

    .line 387
    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    :cond_2
    const-string v0, ".m3u8"

    .line 388
    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result p0

    return p0
.end method

.method private static isWrappedTransportSegmentUrl(Ljava/lang/String;)Z
    .locals 2

    const/4 v0, 0x0

    if-nez p0, :cond_0

    return v0

    .line 393
    :cond_0
    sget-object v1, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {p0, v1}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    const/16 v1, 0x3f

    .line 394
    invoke-virtual {p0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    if-ltz v1, :cond_1

    .line 395
    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    :cond_1
    const-string v1, ".png"

    .line 396
    invoke-virtual {p0, v1}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_2

    const-string v1, ".jpg"

    invoke-virtual {p0, v1}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_2

    const-string v1, ".jpeg"

    invoke-virtual {p0, v1}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_3

    :cond_2
    const/4 v0, 0x1

    :cond_3
    return v0
.end method

.method private localUrl(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 108
    invoke-static {p2}, Ljava/lang/String;->valueOf(Ljava/lang/Object;)Ljava/lang/String;

    move-result-object p2

    sget-object v0, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {p2, v0}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p2

    const/16 v0, 0x3f

    .line 109
    invoke-virtual {p2, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v0

    if-ltz v0, :cond_0

    const/4 v1, 0x0

    .line 110
    invoke-virtual {p2, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p2

    :cond_0
    const-string v0, ".m3u8"

    .line 111
    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    const-string v1, "/segment.ts"

    if-eqz v0, :cond_1

    const-string v1, "/playlist.m3u8"

    goto/16 :goto_0

    :cond_1
    const-string v0, ".mpd"

    .line 112
    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_2

    const-string v1, "/manifest.mpd"

    goto :goto_0

    :cond_2
    const-string v0, ".mp4"

    .line 113
    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_3

    const-string v1, "/video.mp4"

    goto :goto_0

    :cond_3
    const-string v0, ".webm"

    .line 114
    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_4

    const-string v1, "/video.webm"

    goto :goto_0

    :cond_4
    const-string v0, ".m4v"

    .line 115
    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_5

    const-string v1, "/video.m4v"

    goto :goto_0

    :cond_5
    const-string v0, ".ts"

    .line 116
    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_6

    goto :goto_0

    :cond_6
    const-string v0, ".m4s"

    .line 117
    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_7

    const-string v1, "/segment.m4s"

    goto :goto_0

    :cond_7
    const-string v0, ".aac"

    .line 118
    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_8

    const-string v1, "/audio.aac"

    goto :goto_0

    :cond_8
    const-string v0, ".png"

    .line 120
    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_a

    const-string v0, ".jpg"

    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_a

    const-string v0, ".jpeg"

    invoke-virtual {p2, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result p2

    if-eqz p2, :cond_9

    goto :goto_0

    :cond_9
    const-string v1, "/media"

    .line 121
    :cond_a
    :goto_0
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "http://127.0.0.1:"

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    iget v0, p0, Lcom/JVHD/vip/MediaProxyServer;->port:I

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p2

    const-string v0, "/jvhd-media/"

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    return-object p1
.end method

.method private openUpstream(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Lcom/JVHD/vip/MediaProxyServer$Upstream;
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    invoke-static {p1, p2, p3, p4}, Lcom/JVHD/vip/DohHelper;->tryFetch(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Lcom/JVHD/vip/MediaProxyServer$Upstream;

    move-result-object v0

    if-eqz v0, :cond_0

    return-object v0

    .line 252
    :cond_0
    new-instance v0, Ljava/net/URL;

    invoke-direct {v0, p1}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    const/4 p1, 0x0

    const/4 v1, 0x0

    :goto_0
    const/4 v2, 0x6

    if-ge v1, v2, :cond_7

    .line 254
    invoke-virtual {v0}, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;

    move-result-object v2

    check-cast v2, Ljava/net/HttpURLConnection;

    .line 255
    invoke-virtual {v2, p1}, Ljava/net/HttpURLConnection;->setInstanceFollowRedirects(Z)V

    const/16 v3, 0x2ee0

    .line 256
    invoke-virtual {v2, v3}, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V

    const/16 v3, 0x4e20

    .line 257
    invoke-virtual {v2, v3}, Ljava/net/HttpURLConnection;->setReadTimeout(I)V

    .line 258
    invoke-virtual {v2, p1}, Ljava/net/HttpURLConnection;->setUseCaches(Z)V

    .line 259
    invoke-virtual {v2, p4}, Ljava/net/HttpURLConnection;->setRequestMethod(Ljava/lang/String;)V

    const-string v3, "User-Agent"

    const-string v4, "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

    .line 260
    invoke-virtual {v2, v3, v4}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    const-string v3, "Accept"

    const-string v4, "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"

    .line 261
    invoke-virtual {v2, v3, v4}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    const-string v3, "Accept-Encoding"

    const-string v4, "identity"

    .line 262
    invoke-virtual {v2, v3, v4}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    const-string v3, "Accept-Language"

    const-string v4, "vi,en-US;q=0.8,en;q=0.6"

    invoke-virtual {v2, v3, v4}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    .line 263
    invoke-virtual {p2}, Ljava/lang/String;->length()I

    move-result v3

    if-lez v3, :cond_1

    const-string v3, "Referer"

    invoke-virtual {v2, v3, p2}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    .line 264
    :cond_1
    invoke-virtual {p3}, Ljava/lang/String;->length()I

    move-result v3

    if-lez v3, :cond_2

    const-string v3, "Range"

    invoke-virtual {v2, v3, p3}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    .line 265
    :cond_2
    invoke-virtual {v2}, Ljava/net/HttpURLConnection;->getResponseCode()I

    move-result v3

    const/16 v4, 0x12d

    if-eq v3, v4, :cond_4

    const/16 v4, 0x12e

    if-eq v3, v4, :cond_4

    const/16 v4, 0x12f

    if-eq v3, v4, :cond_4

    const/16 v4, 0x133

    if-eq v3, v4, :cond_4

    const/16 v4, 0x134

    if-ne v3, v4, :cond_3

    goto :goto_1

    .line 274
    :cond_3
    new-instance p1, Lcom/JVHD/vip/MediaProxyServer$Upstream;

    invoke-virtual {v0}, Ljava/net/URL;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-direct {p1, v2, v3, p2}, Lcom/JVHD/vip/MediaProxyServer$Upstream;-><init>(Ljava/net/HttpURLConnection;ILjava/lang/String;)V

    return-object p1

    :cond_4
    :goto_1
    const-string v4, "Location"

    .line 267
    invoke-virtual {v2, v4}, Ljava/net/HttpURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    if-eqz v4, :cond_6

    .line 268
    invoke-virtual {v4}, Ljava/lang/String;->length()I

    move-result v5

    if-nez v5, :cond_5

    goto :goto_2

    .line 269
    :cond_5
    new-instance v3, Ljava/net/URL;

    invoke-direct {v3, v0, v4}, Ljava/net/URL;-><init>(Ljava/net/URL;Ljava/lang/String;)V

    .line 270
    invoke-virtual {v2}, Ljava/net/HttpURLConnection;->disconnect()V

    add-int/lit8 v1, v1, 0x1

    move-object v0, v3

    goto/16 :goto_0

    .line 268
    :cond_6
    :goto_2
    new-instance p1, Lcom/JVHD/vip/MediaProxyServer$Upstream;

    invoke-virtual {v0}, Ljava/net/URL;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-direct {p1, v2, v3, p2}, Lcom/JVHD/vip/MediaProxyServer$Upstream;-><init>(Ljava/net/HttpURLConnection;ILjava/lang/String;)V

    return-object p1

    .line 276
    :cond_7
    new-instance p1, Ljava/io/IOException;

    const-string p2, "Too many redirects"

    invoke-direct {p1, p2}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p1
.end method

.method private static parseLong(Ljava/lang/String;)J
    .locals 2

    const-wide/16 v0, -0x1

    if-nez p0, :cond_0

    return-wide v0

    .line 423
    :cond_0
    :try_start_0
    invoke-static {p0}, Ljava/lang/Long;->parseLong(Ljava/lang/String;)J

    move-result-wide v0
    :try_end_0
    .catch Ljava/lang/NumberFormatException; {:try_start_0 .. :try_end_0} :catch_0

    :catch_0
    return-wide v0
.end method

.method private proxy(Ljava/net/Socket;Ljava/lang/String;Ljava/util/Map;Lcom/JVHD/vip/MediaProxyServer$Entry;)V
    .locals 22
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/net/Socket;",
            "Ljava/lang/String;",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Ljava/lang/String;",
            ">;",
            "Lcom/JVHD/vip/MediaProxyServer$Entry;",
            ")V"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    move-object/from16 v1, p0

    move-object/from16 v0, p2

    move-object/from16 v2, p4

    .line 196
    iget-object v3, v2, Lcom/JVHD/vip/MediaProxyServer$Entry;->url:Ljava/lang/String;

    invoke-static {v3}, Lcom/JVHD/vip/MediaProxyServer;->isPlaylistUrl(Ljava/lang/String;)Z

    move-result v3

    .line 197
    iget-object v4, v2, Lcom/JVHD/vip/MediaProxyServer$Entry;->url:Ljava/lang/String;

    invoke-static {v4}, Lcom/JVHD/vip/MediaProxyServer;->isWrappedTransportSegmentUrl(Ljava/lang/String;)Z

    move-result v4

    if-nez v3, :cond_1

    if-eqz v4, :cond_0

    goto :goto_0

    :cond_0
    const-string v5, "range"

    move-object/from16 v6, p3

    .line 198
    invoke-interface {v6, v5}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Ljava/lang/String;

    invoke-static {v5}, Lcom/JVHD/vip/MediaProxyServer;->valueOrEmpty(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    goto :goto_1

    :cond_1
    :goto_0
    const-string v5, ""

    .line 199
    :goto_1
    iget-object v6, v2, Lcom/JVHD/vip/MediaProxyServer$Entry;->url:Ljava/lang/String;

    iget-object v7, v2, Lcom/JVHD/vip/MediaProxyServer$Entry;->referer:Ljava/lang/String;

    const-string v8, "HEAD"

    invoke-virtual {v8, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v9

    if-eqz v9, :cond_2

    move-object v9, v8

    goto :goto_2

    :cond_2
    const-string v9, "GET"

    :goto_2
    invoke-direct {v1, v6, v7, v5, v9}, Lcom/JVHD/vip/MediaProxyServer;->openUpstream(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Lcom/JVHD/vip/MediaProxyServer$Upstream;

    move-result-object v5

    .line 200
    iget-object v6, v5, Lcom/JVHD/vip/MediaProxyServer$Upstream;->connection:Ljava/net/HttpURLConnection;

    .line 201
    iget v10, v5, Lcom/JVHD/vip/MediaProxyServer$Upstream;->code:I

    .line 202
    invoke-virtual {v6}, Ljava/net/HttpURLConnection;->getContentType()Ljava/lang/String;

    move-result-object v7

    invoke-static {v7}, Lcom/JVHD/vip/MediaProxyServer;->valueOrEmpty(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v7

    const/16 v9, 0x12c

    const/4 v11, 0x0

    const/16 v12, 0xc8

    if-lt v10, v12, :cond_4

    if-ge v10, v9, :cond_4

    if-nez v3, :cond_3

    .line 203
    sget-object v3, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {v7, v3}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v3

    const-string v13, "mpegurl"

    invoke-virtual {v3, v13}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v3

    if-eqz v3, :cond_4

    :cond_3
    const/4 v3, 0x1

    goto :goto_3

    :cond_4
    const/4 v3, 0x0

    :goto_3
    const/4 v13, 0x0

    const/16 v14, 0x190

    if-lt v10, v14, :cond_5

    .line 206
    :try_start_0
    invoke-virtual {v6}, Ljava/net/HttpURLConnection;->getErrorStream()Ljava/io/InputStream;

    move-result-object v13

    goto :goto_4

    :cond_5
    invoke-virtual {v6}, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;

    move-result-object v13
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    :goto_4
    move-object v15, v13

    if-eqz v3, :cond_7

    .line 207
    :try_start_1
    invoke-virtual {v8, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v3

    if-nez v3, :cond_7

    const/high16 v0, 0x800000

    .line 208
    invoke-static {v15, v0}, Lcom/JVHD/vip/MediaProxyServer;->readLimited(Ljava/io/InputStream;I)[B

    move-result-object v0

    .line 209
    new-instance v3, Ljava/lang/String;

    sget-object v4, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v3, v0, v4}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    iget-object v0, v5, Lcom/JVHD/vip/MediaProxyServer$Upstream;->finalUrl:Ljava/lang/String;

    iget-object v2, v2, Lcom/JVHD/vip/MediaProxyServer$Entry;->referer:Ljava/lang/String;

    invoke-direct {v1, v3, v0, v2}, Lcom/JVHD/vip/MediaProxyServer;->rewritePlaylist(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    .line 210
    sget-object v2, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {v0, v2}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v0

    .line 211
    new-instance v8, Ljava/io/BufferedOutputStream;

    invoke-virtual/range {p1 .. p1}, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v2

    invoke-direct {v8, v2}, Ljava/io/BufferedOutputStream;-><init>(Ljava/io/OutputStream;)V

    const/16 v3, 0xc8

    const-string v4, "application/vnd.apple.mpegurl"

    .line 212
    array-length v2, v0

    int-to-long v5, v2

    const/4 v7, 0x0

    move-object v2, v8

    invoke-static/range {v2 .. v7}, Lcom/JVHD/vip/MediaProxyServer;->sendHeaders(Ljava/io/OutputStream;ILjava/lang/String;JLjava/util/Map;)V

    .line 213
    invoke-virtual {v8, v0}, Ljava/io/OutputStream;->write([B)V

    .line 214
    invoke-virtual {v8}, Ljava/io/OutputStream;->flush()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    if-eqz v15, :cond_6

    .line 247
    :try_start_2
    invoke-virtual {v15}, Ljava/io/InputStream;->close()V
    :try_end_2
    .catch Ljava/io/IOException; {:try_start_2 .. :try_end_2} :catch_0

    :catch_0
    :cond_6
    return-void

    :cond_7
    const-string v2, "application/octet-stream"

    if-eqz v4, :cond_10

    if-lt v10, v12, :cond_10

    if-ge v10, v9, :cond_10

    .line 218
    :try_start_3
    new-instance v3, Ljava/io/BufferedOutputStream;

    invoke-virtual/range {p1 .. p1}, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v4

    invoke-direct {v3, v4}, Ljava/io/BufferedOutputStream;-><init>(Ljava/io/OutputStream;)V

    .line 219
    invoke-virtual {v8, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_9

    const/16 v17, 0xc8

    const-string v18, "video/mp2t"

    const-wide/16 v19, -0x1

    const/16 v21, 0x0

    move-object/from16 v16, v3

    .line 220
    invoke-static/range {v16 .. v21}, Lcom/JVHD/vip/MediaProxyServer;->sendHeaders(Ljava/io/OutputStream;ILjava/lang/String;JLjava/util/Map;)V

    .line 221
    invoke-virtual {v3}, Ljava/io/OutputStream;->flush()V
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    if-eqz v15, :cond_8

    .line 247
    :try_start_4
    invoke-virtual {v15}, Ljava/io/InputStream;->close()V
    :try_end_4
    .catch Ljava/io/IOException; {:try_start_4 .. :try_end_4} :catch_1

    :catch_1
    :cond_8
    return-void

    :cond_9
    const/high16 v0, 0x2000000

    .line 224
    :try_start_5
    invoke-static {v15, v0}, Lcom/JVHD/vip/MediaProxyServer;->readLimited(Ljava/io/InputStream;I)[B

    move-result-object v0

    .line 225
    invoke-static {v0}, Lcom/JVHD/vip/MediaProxyServer;->findTransportStreamOffset([B)I

    move-result v4

    if-ltz v4, :cond_a

    move v5, v4

    goto :goto_5

    .line 226
    :cond_a
    invoke-static {v0}, Lcom/JVHD/vip/MediaProxyServer;->findFragmentedMp4Offset([B)I

    move-result v5

    :goto_5
    if-ltz v4, :cond_b

    const-string v7, "video/mp2t"

    goto :goto_6

    :cond_b
    if-ltz v5, :cond_c

    const-string v7, "video/mp4"

    :cond_c
    :goto_6
    if-gez v5, :cond_d

    goto :goto_7

    :cond_d
    move v11, v5

    :goto_7
    const/16 v17, 0xc8

    .line 229
    invoke-virtual {v7}, Ljava/lang/String;->length()I

    move-result v4

    if-lez v4, :cond_e

    move-object/from16 v18, v7

    goto :goto_8

    :cond_e
    move-object/from16 v18, v2

    :goto_8
    array-length v2, v0

    sub-int/2addr v2, v11

    int-to-long v4, v2

    const/16 v21, 0x0

    move-object/from16 v16, v3

    move-wide/from16 v19, v4

    invoke-static/range {v16 .. v21}, Lcom/JVHD/vip/MediaProxyServer;->sendHeaders(Ljava/io/OutputStream;ILjava/lang/String;JLjava/util/Map;)V

    .line 230
    array-length v2, v0

    sub-int/2addr v2, v11

    invoke-virtual {v3, v0, v11, v2}, Ljava/io/OutputStream;->write([BII)V

    .line 231
    invoke-virtual {v3}, Ljava/io/OutputStream;->flush()V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_0

    if-eqz v15, :cond_f

    .line 247
    :try_start_6
    invoke-virtual {v15}, Ljava/io/InputStream;->close()V
    :try_end_6
    .catch Ljava/io/IOException; {:try_start_6 .. :try_end_6} :catch_2

    :catch_2
    :cond_f
    return-void

    :cond_10
    :try_start_7
    const-string v3, "Content-Length"

    .line 235
    invoke-virtual {v6, v3}, Ljava/net/HttpURLConnection;->getHeaderField(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v3

    invoke-static {v3}, Lcom/JVHD/vip/MediaProxyServer;->parseLong(Ljava/lang/String;)J

    move-result-wide v12

    .line 236
    new-instance v14, Ljava/util/HashMap;

    invoke-direct {v14}, Ljava/util/HashMap;-><init>()V

    const-string v3, "Content-Range"

    .line 237
    invoke-static {v6, v14, v3}, Lcom/JVHD/vip/MediaProxyServer;->copyHeader(Ljava/net/HttpURLConnection;Ljava/util/Map;Ljava/lang/String;)V

    const-string v3, "Accept-Ranges"

    .line 238
    invoke-static {v6, v14, v3}, Lcom/JVHD/vip/MediaProxyServer;->copyHeader(Ljava/net/HttpURLConnection;Ljava/util/Map;Ljava/lang/String;)V

    .line 239
    new-instance v3, Ljava/io/BufferedOutputStream;

    invoke-virtual/range {p1 .. p1}, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v4

    invoke-direct {v3, v4}, Ljava/io/BufferedOutputStream;-><init>(Ljava/io/OutputStream;)V

    .line 240
    invoke-virtual {v7}, Ljava/lang/String;->length()I

    move-result v4

    if-lez v4, :cond_11

    move-object v11, v7

    goto :goto_9

    :cond_11
    move-object v11, v2

    :goto_9
    move-object v9, v3

    invoke-static/range {v9 .. v14}, Lcom/JVHD/vip/MediaProxyServer;->sendHeaders(Ljava/io/OutputStream;ILjava/lang/String;JLjava/util/Map;)V

    .line 241
    invoke-virtual {v8, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_12

    if-eqz v15, :cond_12

    invoke-static {v15, v3}, Lcom/JVHD/vip/MediaProxyServer;->copy(Ljava/io/InputStream;Ljava/io/OutputStream;)V

    .line 242
    :cond_12
    invoke-virtual {v3}, Ljava/io/OutputStream;->flush()V
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_0

    if-eqz v15, :cond_13

    .line 247
    :try_start_8
    invoke-virtual {v15}, Ljava/io/InputStream;->close()V
    :try_end_8
    .catch Ljava/io/IOException; {:try_start_8 .. :try_end_8} :catch_3

    :catch_3
    :cond_13
    return-void

    :catchall_0
    move-exception v0

    move-object v13, v15

    goto :goto_a

    :catchall_1
    move-exception v0

    :goto_a
    if-eqz v13, :cond_14

    :try_start_9
    invoke-virtual {v13}, Ljava/io/InputStream;->close()V
    :try_end_9
    .catch Ljava/io/IOException; {:try_start_9 .. :try_end_9} :catch_4

    .line 248
    :catch_4
    :cond_14
    throw v0
.end method

.method private proxyChildUrl(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 307
    :try_start_0
    new-instance v0, Ljava/net/URL;

    new-instance v1, Ljava/net/URL;

    invoke-direct {v1, p1}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    invoke-direct {v0, v1, p2}, Ljava/net/URL;-><init>(Ljava/net/URL;Ljava/lang/String;)V

    .line 308
    invoke-virtual {v0}, Ljava/net/URL;->getProtocol()Ljava/lang/String;

    move-result-object p1

    sget-object v1, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {p1, v1}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p1

    const-string v1, "http"

    .line 309
    invoke-virtual {v1, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-nez v1, :cond_0

    const-string v1, "https"

    invoke-virtual {v1, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p1

    if-nez p1, :cond_0

    return-object p2

    .line 310
    :cond_0
    invoke-virtual {v0}, Ljava/net/URL;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-direct {p0, p1, p3}, Lcom/JVHD/vip/MediaProxyServer;->register(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return-object p1

    :catchall_0
    return-object p2
.end method

.method private static readLimited(Ljava/io/InputStream;I)[B
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    const/4 v0, 0x0

    if-nez p0, :cond_0

    new-array p0, v0, [B

    return-object p0

    .line 316
    :cond_0
    new-instance v1, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v1}, Ljava/io/ByteArrayOutputStream;-><init>()V

    const/16 v2, 0x4000

    new-array v2, v2, [B

    const/4 v3, 0x0

    .line 320
    :goto_0
    invoke-virtual {p0, v2}, Ljava/io/InputStream;->read([B)I

    move-result v4

    const/4 v5, -0x1

    if-eq v4, v5, :cond_2

    add-int/2addr v3, v4

    if-gt v3, p1, :cond_1

    .line 323
    invoke-virtual {v1, v2, v0, v4}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    goto :goto_0

    .line 322
    :cond_1
    new-instance p0, Ljava/io/IOException;

    const-string p1, "Playlist too large"

    invoke-direct {p0, p1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 325
    :cond_2
    invoke-virtual {v1}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object p0

    return-object p0
.end method

.method private static reason(I)Ljava/lang/String;
    .locals 1

    const/16 v0, 0xc8

    if-eq p0, v0, :cond_8

    const/16 v0, 0xcc

    if-eq p0, v0, :cond_7

    const/16 v0, 0xce

    if-eq p0, v0, :cond_6

    const/16 v0, 0x190

    if-eq p0, v0, :cond_5

    const/16 v0, 0x1a0

    if-eq p0, v0, :cond_4

    const/16 v0, 0x1af

    if-eq p0, v0, :cond_3

    const/16 v0, 0x1f4

    if-eq p0, v0, :cond_2

    const/16 v0, 0x1f6

    if-eq p0, v0, :cond_1

    const/16 v0, 0x1f7

    if-eq p0, v0, :cond_0

    packed-switch p0, :pswitch_data_0

    const-string p0, "Response"

    return-object p0

    :pswitch_0
    const-string p0, "Method Not Allowed"

    return-object p0

    :pswitch_1
    const-string p0, "Not Found"

    return-object p0

    :pswitch_2
    const-string p0, "Forbidden"

    return-object p0

    :cond_0
    const-string p0, "Service Unavailable"

    return-object p0

    :cond_1
    const-string p0, "Bad Gateway"

    return-object p0

    :cond_2
    const-string p0, "Internal Server Error"

    return-object p0

    :cond_3
    const-string p0, "Request Header Fields Too Large"

    return-object p0

    :cond_4
    const-string p0, "Range Not Satisfiable"

    return-object p0

    :cond_5
    const-string p0, "Bad Request"

    return-object p0

    :cond_6
    const-string p0, "Partial Content"

    return-object p0

    :cond_7
    const-string p0, "No Content"

    return-object p0

    :cond_8
    const-string p0, "OK"

    return-object p0

    :pswitch_data_0
    .packed-switch 0x193
        :pswitch_2
        :pswitch_1
        :pswitch_0
    .end packed-switch
.end method

.method private declared-synchronized register(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 6

    monitor-enter p0

    .line 96
    :try_start_0
    invoke-direct {p0}, Lcom/JVHD/vip/MediaProxyServer;->cleanupIfNeeded()V

    .line 97
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, "\n"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    .line 98
    iget-object v1, p0, Lcom/JVHD/vip/MediaProxyServer;->reverseEntries:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {v1, v0}, Ljava/util/concurrent/ConcurrentHashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Ljava/lang/String;

    if-eqz v1, :cond_0

    .line 99
    iget-object v2, p0, Lcom/JVHD/vip/MediaProxyServer;->entries:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {v2, v1}, Ljava/util/concurrent/ConcurrentHashMap;->containsKey(Ljava/lang/Object;)Z

    move-result v2

    if-eqz v2, :cond_0

    invoke-direct {p0, v1, p1}, Lcom/JVHD/vip/MediaProxyServer;->localUrl(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    monitor-exit p0

    return-object p1

    .line 100
    :cond_0
    :try_start_1
    invoke-static {}, Ljava/util/UUID;->randomUUID()Ljava/util/UUID;

    move-result-object v1

    invoke-virtual {v1}, Ljava/util/UUID;->toString()Ljava/lang/String;

    move-result-object v1

    const-string v2, "-"

    const-string v3, ""

    invoke-virtual {v1, v2, v3}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v1

    .line 101
    iget-object v2, p0, Lcom/JVHD/vip/MediaProxyServer;->entries:Ljava/util/concurrent/ConcurrentHashMap;

    new-instance v3, Lcom/JVHD/vip/MediaProxyServer$Entry;

    invoke-static {}, Ljava/lang/System;->currentTimeMillis()J

    move-result-wide v4

    invoke-direct {v3, p1, p2, v4, v5}, Lcom/JVHD/vip/MediaProxyServer$Entry;-><init>(Ljava/lang/String;Ljava/lang/String;J)V

    invoke-virtual {v2, v1, v3}, Ljava/util/concurrent/ConcurrentHashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 102
    iget-object p2, p0, Lcom/JVHD/vip/MediaProxyServer;->reverseEntries:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {p2, v0, v1}, Ljava/util/concurrent/ConcurrentHashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 103
    invoke-direct {p0, v1, p1}, Lcom/JVHD/vip/MediaProxyServer;->localUrl(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    monitor-exit p0

    return-object p1

    :catchall_0
    move-exception p1

    monitor-exit p0

    throw p1
.end method

.method private rewritePlaylist(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 9

    const-string v0, "\r\n"

    const-string v1, "\n"

    .line 280
    invoke-virtual {p1, v0, v1}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v0

    const/16 v2, 0xd

    const/16 v3, 0xa

    invoke-virtual {v0, v2, v3}, Ljava/lang/String;->replace(CC)Ljava/lang/String;

    move-result-object v0

    const/4 v2, -0x1

    invoke-virtual {v0, v1, v2}, Ljava/lang/String;->split(Ljava/lang/String;I)[Ljava/lang/String;

    move-result-object v0

    .line 281
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-virtual {p1}, Ljava/lang/String;->length()I

    move-result p1

    array-length v2, v0

    mul-int/lit8 v2, v2, 0x18

    add-int/2addr p1, v2

    invoke-direct {v1, p1}, Ljava/lang/StringBuilder;-><init>(I)V

    const/4 p1, 0x0

    .line 282
    :goto_0
    array-length v2, v0

    if-ge p1, v2, :cond_6

    .line 283
    aget-object v2, v0, p1

    .line 284
    invoke-virtual {v2}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v4

    .line 285
    invoke-virtual {v4}, Ljava/lang/String;->length()I

    move-result v5

    const-string v6, "#"

    if-lez v5, :cond_0

    invoke-virtual {v4, v6}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v5

    if-nez v5, :cond_0

    .line 286
    invoke-direct {p0, p2, v4, p3}, Lcom/JVHD/vip/MediaProxyServer;->proxyChildUrl(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    goto :goto_4

    .line 287
    :cond_0
    invoke-virtual {v4, v6}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v5

    if-eqz v5, :cond_4

    sget-object v5, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {v4, v5}, Ljava/lang/String;->toUpperCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v4

    const-string v5, "URI="

    invoke-virtual {v4, v5}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v4

    if-eqz v4, :cond_4

    .line 288
    sget-object v4, Lcom/JVHD/vip/MediaProxyServer;->HLS_URI:Ljava/util/regex/Pattern;

    invoke-virtual {v4, v2}, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;

    move-result-object v2

    .line 289
    new-instance v4, Ljava/lang/StringBuffer;

    invoke-direct {v4}, Ljava/lang/StringBuffer;-><init>()V

    .line 290
    :goto_1
    invoke-virtual {v2}, Ljava/util/regex/Matcher;->find()Z

    move-result v6

    if-eqz v6, :cond_3

    const/4 v6, 0x2

    .line 291
    invoke-virtual {v2, v6}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v7

    if-eqz v7, :cond_1

    invoke-virtual {v2, v6}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v7

    goto :goto_2

    :cond_1
    const/4 v7, 0x3

    invoke-virtual {v2, v7}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v7

    .line 292
    :goto_2
    invoke-virtual {v2, v6}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v6

    if-eqz v6, :cond_2

    const-string v6, "\""

    goto :goto_3

    :cond_2
    const-string v6, "\'"

    .line 293
    :goto_3
    invoke-direct {p0, p2, v7, p3}, Lcom/JVHD/vip/MediaProxyServer;->proxyChildUrl(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v7

    .line 294
    new-instance v8, Ljava/lang/StringBuilder;

    invoke-direct {v8}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v8, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v8

    invoke-virtual {v8, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v8

    invoke-virtual {v8, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    invoke-virtual {v7, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v6

    invoke-virtual {v6}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v6

    invoke-static {v6}, Ljava/util/regex/Matcher;->quoteReplacement(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v2, v4, v6}, Ljava/util/regex/Matcher;->appendReplacement(Ljava/lang/StringBuffer;Ljava/lang/String;)Ljava/util/regex/Matcher;

    goto :goto_1

    .line 296
    :cond_3
    invoke-virtual {v2, v4}, Ljava/util/regex/Matcher;->appendTail(Ljava/lang/StringBuffer;)Ljava/lang/StringBuffer;

    .line 297
    invoke-virtual {v4}, Ljava/lang/StringBuffer;->toString()Ljava/lang/String;

    move-result-object v2

    .line 299
    :cond_4
    :goto_4
    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 300
    array-length v2, v0

    add-int/lit8 v2, v2, -0x1

    if-ge p1, v2, :cond_5

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    :cond_5
    add-int/lit8 p1, p1, 0x1

    goto/16 :goto_0

    .line 302
    :cond_6
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    return-object p1
.end method

.method private static sanitizeReferer(Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 91
    invoke-static {p0}, Lcom/JVHD/vip/MediaProxyServer;->isHttpUrl(Ljava/lang/String;)Z

    move-result v0

    const-string v1, ""

    if-nez v0, :cond_0

    return-object v1

    :cond_0
    const-string v0, "\r"

    .line 92
    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p0

    const-string v0, "\n"

    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private static sendHeaders(Ljava/io/OutputStream;ILjava/lang/String;JLjava/util/Map;)V
    .locals 4
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/io/OutputStream;",
            "I",
            "Ljava/lang/String;",
            "J",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Ljava/lang/String;",
            ">;)V"
        }
    .end annotation

    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 348
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "HTTP/1.1 "

    .line 349
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const/16 v2, 0x20

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-static {p1}, Lcom/JVHD/vip/MediaProxyServer;->reason(I)Ljava/lang/String;

    move-result-object p1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v1, "\r\n"

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string p1, "Content-Type: "

    .line 350
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    if-nez p2, :cond_0

    const-string p2, "application/octet-stream"

    goto :goto_0

    :cond_0
    const-string v2, "\r"

    const-string v3, ""

    invoke-virtual {p2, v2, v3}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p2

    const-string v2, "\n"

    invoke-virtual {p2, v2, v3}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p2

    :goto_0
    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-wide/16 p1, 0x0

    cmp-long v2, p3, p1

    if-ltz v2, :cond_1

    const-string p1, "Content-Length: "

    .line 351
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, p3, p4}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    :cond_1
    const-string p1, "Access-Control-Allow-Origin: *\r\n"

    .line 352
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string p1, "Access-Control-Allow-Headers: Range, Content-Type\r\n"

    .line 353
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string p1, "Access-Control-Expose-Headers: Content-Length, Content-Range, Accept-Ranges\r\n"

    .line 354
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string p1, "Cache-Control: no-store\r\n"

    .line 355
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    if-eqz p5, :cond_2

    .line 357
    invoke-interface {p5}, Ljava/util/Map;->entrySet()Ljava/util/Set;

    move-result-object p1

    invoke-interface {p1}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    move-result-object p1

    :goto_1
    invoke-interface {p1}, Ljava/util/Iterator;->hasNext()Z

    move-result p2

    if-eqz p2, :cond_2

    invoke-interface {p1}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object p2

    check-cast p2, Ljava/util/Map$Entry;

    invoke-interface {p2}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    move-result-object p3

    check-cast p3, Ljava/lang/String;

    invoke-virtual {v0, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p3

    const-string p4, ": "

    invoke-virtual {p3, p4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p3

    invoke-interface {p2}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    move-result-object p2

    check-cast p2, Ljava/lang/String;

    invoke-virtual {p3, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    goto :goto_1

    :cond_2
    const-string p1, "Connection: close\r\n\r\n"

    .line 359
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 360
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    sget-object p2, Ljava/nio/charset/StandardCharsets;->ISO_8859_1:Ljava/nio/charset/Charset;

    invoke-virtual {p1, p2}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p1

    invoke-virtual {p0, p1}, Ljava/io/OutputStream;->write([B)V

    return-void
.end method

.method private static sendSmallResponse(Ljava/net/Socket;ILjava/lang/String;Ljava/lang/String;)V
    .locals 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 340
    sget-object v0, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-virtual {p3, v0}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p3

    .line 341
    new-instance v6, Ljava/io/BufferedOutputStream;

    invoke-virtual {p0}, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object p0

    invoke-direct {v6, p0}, Ljava/io/BufferedOutputStream;-><init>(Ljava/io/OutputStream;)V

    .line 342
    array-length p0, p3

    int-to-long v3, p0

    const/4 v5, 0x0

    move-object v0, v6

    move v1, p1

    move-object v2, p2

    invoke-static/range {v0 .. v5}, Lcom/JVHD/vip/MediaProxyServer;->sendHeaders(Ljava/io/OutputStream;ILjava/lang/String;JLjava/util/Map;)V

    .line 343
    invoke-virtual {v6, p3}, Ljava/io/OutputStream;->write([B)V

    .line 344
    invoke-virtual {v6}, Ljava/io/OutputStream;->flush()V

    return-void
.end method

.method private static valueOrEmpty(Ljava/lang/String;)Ljava/lang/String;
    .locals 0

    if-nez p0, :cond_0

    const-string p0, ""

    :cond_0
    return-object p0
.end method
