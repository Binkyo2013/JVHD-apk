.class Lcom/bintv/launcher/RawResponse;
.super Ljava/lang/Object;
.source "DohHelper.java"


# instance fields
.field final body:Ljava/io/InputStream;

.field final code:I

.field final headers:Ljava/util/List;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/List<",
            "[",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation
.end field

.field final message:Ljava/lang/String;

.field final socket:Ljavax/net/ssl/SSLSocket;


# direct methods
.method constructor <init>(ILjava/lang/String;Ljavax/net/ssl/SSLSocket;Ljava/io/InputStream;)V
    .locals 1

    .line 247
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 243
    new-instance v0, Ljava/util/ArrayList;

    invoke-direct {v0}, Ljava/util/ArrayList;-><init>()V

    iput-object v0, p0, Lcom/bintv/launcher/RawResponse;->headers:Ljava/util/List;

    .line 248
    iput p1, p0, Lcom/bintv/launcher/RawResponse;->code:I

    .line 249
    iput-object p2, p0, Lcom/bintv/launcher/RawResponse;->message:Ljava/lang/String;

    .line 250
    iput-object p3, p0, Lcom/bintv/launcher/RawResponse;->socket:Ljavax/net/ssl/SSLSocket;

    .line 251
    iput-object p4, p0, Lcom/bintv/launcher/RawResponse;->body:Ljava/io/InputStream;

    return-void
.end method

.method static synthetic access$000(Ljava/util/List;Ljava/lang/String;)Ljava/lang/String;
    .locals 0

    .line 240
    invoke-static {p0, p1}, Lcom/bintv/launcher/RawResponse;->findHeader(Ljava/util/List;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private static findHeader(Ljava/util/List;Ljava/lang/String;)Ljava/lang/String;
    .locals 3
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Ljava/util/List<",
            "[",
            "Ljava/lang/String;",
            ">;",
            "Ljava/lang/String;",
            ")",
            "Ljava/lang/String;"
        }
    .end annotation

    const/4 v0, 0x0

    const/4 v1, 0x0

    .line 318
    :goto_0
    invoke-interface {p0}, Ljava/util/List;->size()I

    move-result v2

    if-ge v1, v2, :cond_1

    .line 319
    invoke-interface {p0, v1}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, [Ljava/lang/String;

    aget-object v2, v2, v0

    invoke-virtual {v2, p1}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_0

    invoke-interface {p0, v1}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object p0

    check-cast p0, [Ljava/lang/String;

    const/4 p1, 0x1

    aget-object p0, p0, p1

    return-object p0

    :cond_0
    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    :cond_1
    const/4 p0, 0x0

    return-object p0
.end method

.method static read(Ljavax/net/ssl/SSLSocket;)Lcom/bintv/launcher/RawResponse;
    .locals 14
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 280
    invoke-virtual {p0}, Ljavax/net/ssl/SSLSocket;->getInputStream()Ljava/io/InputStream;

    move-result-object v0

    const/4 v1, 0x0

    .line 282
    filled-new-array {v1, v1, v1, v1}, [I

    move-result-object v2

    .line 283
    new-instance v3, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v3}, Ljava/io/ByteArrayOutputStream;-><init>()V

    const/4 v4, 0x0

    .line 285
    :goto_0
    invoke-virtual {v0}, Ljava/io/InputStream;->read()I

    move-result v5

    if-ltz v5, :cond_7

    .line 287
    invoke-virtual {v3, v5}, Ljava/io/ByteArrayOutputStream;->write(I)V

    const/4 v6, 0x1

    .line 288
    aget v7, v2, v6

    aput v7, v2, v1

    const/4 v8, 0x2

    aget v9, v2, v8

    aput v9, v2, v6

    const/4 v10, 0x3

    aget v11, v2, v10

    aput v11, v2, v8

    aput v5, v2, v10

    add-int/2addr v4, v6

    const/4 v12, 0x4

    if-lt v4, v12, :cond_5

    const/16 v13, 0xd

    if-ne v7, v13, :cond_5

    const/16 v7, 0xa

    if-ne v9, v7, :cond_5

    if-ne v11, v13, :cond_5

    if-ne v5, v7, :cond_5

    .line 293
    invoke-virtual {v3}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object v2

    .line 294
    new-instance v3, Ljava/lang/String;

    array-length v4, v2

    sub-int/2addr v4, v12

    const-string v5, "UTF-8"

    invoke-direct {v3, v2, v1, v4, v5}, Ljava/lang/String;-><init>([BIILjava/lang/String;)V

    const-string v4, "\r\n"

    .line 295
    invoke-virtual {v3, v4}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v3

    .line 296
    array-length v4, v3

    if-eqz v4, :cond_4

    aget-object v4, v3, v1

    const-string v5, "HTTP/"

    invoke-virtual {v4, v5}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v4

    if-eqz v4, :cond_4

    .line 297
    aget-object v4, v3, v1

    const-string v5, " "

    invoke-virtual {v4, v5, v10}, Ljava/lang/String;->split(Ljava/lang/String;I)[Ljava/lang/String;

    move-result-object v4

    .line 298
    aget-object v5, v4, v6

    invoke-static {v5}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v5

    .line 299
    array-length v7, v4

    if-le v7, v8, :cond_0

    aget-object v4, v4, v8

    goto :goto_1

    :cond_0
    const-string v4, ""

    .line 300
    :goto_1
    new-instance v7, Ljava/util/ArrayList;

    invoke-direct {v7}, Ljava/util/ArrayList;-><init>()V

    .line 301
    :goto_2
    array-length v8, v3

    if-ge v6, v8, :cond_2

    .line 302
    aget-object v8, v3, v6

    const/16 v9, 0x3a

    invoke-virtual {v8, v9}, Ljava/lang/String;->indexOf(I)I

    move-result v8

    if-gtz v8, :cond_1

    goto :goto_3

    .line 304
    :cond_1
    aget-object v9, v3, v6

    invoke-virtual {v9, v1, v8}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v9

    invoke-virtual {v9}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v9

    aget-object v10, v3, v6

    add-int/lit8 v8, v8, 0x1

    invoke-virtual {v10, v8}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v8

    invoke-virtual {v8}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v8

    filled-new-array {v9, v8}, [Ljava/lang/String;

    move-result-object v8

    invoke-interface {v7, v8}, Ljava/util/List;->add(Ljava/lang/Object;)Z

    :goto_3
    add-int/lit8 v6, v6, 0x1

    goto :goto_2

    .line 306
    :cond_2
    new-instance v1, Lcom/bintv/launcher/LeftoverStream;

    invoke-direct {v1, v0, v2}, Lcom/bintv/launcher/LeftoverStream;-><init>(Ljava/io/InputStream;[B)V

    const-string v0, "Transfer-Encoding"

    .line 307
    invoke-static {v7, v0}, Lcom/bintv/launcher/RawResponse;->findHeader(Ljava/util/List;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    if-eqz v0, :cond_3

    .line 308
    sget-object v2, Ljava/util/Locale;->US:Ljava/util/Locale;

    invoke-virtual {v0, v2}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v0

    const-string v2, "chunked"

    invoke-virtual {v0, v2}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v0

    if-eqz v0, :cond_3

    new-instance v0, Lcom/bintv/launcher/ChunkedInputStream;

    invoke-direct {v0, v1}, Lcom/bintv/launcher/ChunkedInputStream;-><init>(Ljava/io/InputStream;)V

    move-object v1, v0

    .line 309
    :cond_3
    new-instance v0, Lcom/bintv/launcher/RawResponse$1;

    invoke-direct {v0, v5, v4, p0, v1}, Lcom/bintv/launcher/RawResponse$1;-><init>(ILjava/lang/String;Ljavax/net/ssl/SSLSocket;Ljava/io/InputStream;)V

    return-object v0

    .line 296
    :cond_4
    new-instance p0, Ljava/io/IOException;

    const-string v0, "bad status line"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 291
    :cond_5
    invoke-virtual {v3}, Ljava/io/ByteArrayOutputStream;->size()I

    move-result v5

    const/high16 v6, 0x10000

    if-gt v5, v6, :cond_6

    goto/16 :goto_0

    :cond_6
    new-instance p0, Ljava/io/IOException;

    const-string v0, "headers too large"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0

    .line 286
    :cond_7
    new-instance p0, Ljava/io/IOException;

    const-string v0, "unexpected eof in headers"

    invoke-direct {p0, v0}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw p0
.end method


# virtual methods
.method close()V
    .locals 1

    .line 275
    :try_start_0
    iget-object v0, p0, Lcom/bintv/launcher/RawResponse;->body:Ljava/io/InputStream;

    invoke-virtual {v0}, Ljava/io/InputStream;->close()V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    .line 276
    :catch_0
    :try_start_1
    iget-object v0, p0, Lcom/bintv/launcher/RawResponse;->socket:Ljavax/net/ssl/SSLSocket;

    invoke-virtual {v0}, Ljavax/net/ssl/SSLSocket;->close()V
    :try_end_1
    .catch Ljava/io/IOException; {:try_start_1 .. :try_end_1} :catch_1

    :catch_1
    return-void
.end method

.method header(Ljava/lang/String;)Ljava/lang/String;
    .locals 3

    const/4 v0, 0x0

    const/4 v1, 0x0

    .line 255
    :goto_0
    iget-object v2, p0, Lcom/bintv/launcher/RawResponse;->headers:Ljava/util/List;

    invoke-interface {v2}, Ljava/util/List;->size()I

    move-result v2

    if-ge v1, v2, :cond_1

    .line 256
    iget-object v2, p0, Lcom/bintv/launcher/RawResponse;->headers:Ljava/util/List;

    invoke-interface {v2, v1}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, [Ljava/lang/String;

    aget-object v2, v2, v0

    invoke-virtual {v2, p1}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_0

    iget-object p1, p0, Lcom/bintv/launcher/RawResponse;->headers:Ljava/util/List;

    invoke-interface {p1, v1}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, [Ljava/lang/String;

    const/4 v0, 0x1

    aget-object p1, p1, v0

    return-object p1

    :cond_0
    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    :cond_1
    const/4 p1, 0x0

    return-object p1
.end method

.method readBodyText(I)Ljava/lang/String;
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 262
    new-instance v0, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v0}, Ljava/io/ByteArrayOutputStream;-><init>()V

    const/16 v1, 0x1000

    new-array v1, v1, [B

    const/4 v2, 0x0

    const/4 v3, 0x0

    :goto_0
    if-ge v3, p1, :cond_1

    .line 266
    iget-object v4, p0, Lcom/bintv/launcher/RawResponse;->body:Ljava/io/InputStream;

    invoke-virtual {v4, v1}, Ljava/io/InputStream;->read([B)I

    move-result v4

    if-gez v4, :cond_0

    goto :goto_1

    .line 268
    :cond_0
    invoke-virtual {v0, v1, v2, v4}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    add-int/2addr v3, v4

    goto :goto_0

    .line 271
    :cond_1
    :goto_1
    new-instance p1, Ljava/lang/String;

    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object v0

    const-string v1, "UTF-8"

    invoke-direct {p1, v0, v1}, Ljava/lang/String;-><init>([BLjava/lang/String;)V

    return-object p1
.end method
