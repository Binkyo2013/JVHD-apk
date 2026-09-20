.class final Lcom/JVHD/vip/ChunkedInputStream;
.super Ljava/io/InputStream;
.source "DohHelper.java"


# instance fields
.field private done:Z

.field private final in:Ljava/io/InputStream;

.field private remaining:J


# direct methods
.method constructor <init>(Ljava/io/InputStream;)V
    .locals 0

    .line 371
    invoke-direct {p0}, Ljava/io/InputStream;-><init>()V

    .line 372
    iput-object p1, p0, Lcom/JVHD/vip/ChunkedInputStream;->in:Ljava/io/InputStream;

    return-void
.end method

.method private static readLine(Ljava/io/InputStream;)Ljava/lang/String;
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 405
    new-instance v0, Ljava/io/ByteArrayOutputStream;

    invoke-direct {v0}, Ljava/io/ByteArrayOutputStream;-><init>()V

    .line 408
    :cond_0
    invoke-virtual {p0}, Ljava/io/InputStream;->read()I

    move-result v1

    const/4 v2, 0x0

    if-gez v1, :cond_1

    return-object v2

    :cond_1
    const/16 v3, 0xa

    if-ne v1, v3, :cond_3

    .line 411
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object p0

    .line 412
    array-length v0, p0

    if-lez v0, :cond_2

    add-int/lit8 v1, v0, -0x1

    .line 413
    aget-byte v1, p0, v1

    const/16 v2, 0xd

    if-ne v1, v2, :cond_2

    add-int/lit8 v0, v0, -0x1

    .line 414
    :cond_2
    new-instance v1, Ljava/lang/String;

    const/4 v2, 0x0

    const-string v3, "UTF-8"

    invoke-direct {v1, p0, v2, v0, v3}, Ljava/lang/String;-><init>([BIILjava/lang/String;)V

    return-object v1

    .line 416
    :cond_3
    invoke-virtual {v0, v1}, Ljava/io/ByteArrayOutputStream;->write(I)V

    .line 418
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->size()I

    move-result v1

    const/16 v3, 0x2000

    if-le v1, v3, :cond_0

    return-object v2
.end method


# virtual methods
.method public close()V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 401
    iget-object v0, p0, Lcom/JVHD/vip/ChunkedInputStream;->in:Ljava/io/InputStream;

    invoke-virtual {v0}, Ljava/io/InputStream;->close()V

    return-void
.end method

.method public read()I
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    const/4 v0, 0x1

    new-array v1, v0, [B

    const/4 v2, 0x0

    .line 377
    invoke-virtual {p0, v1, v2, v0}, Lcom/JVHD/vip/ChunkedInputStream;->read([BII)I

    move-result v0

    if-lez v0, :cond_0

    aget-byte v0, v1, v2

    and-int/lit16 v0, v0, 0xff

    goto :goto_0

    :cond_0
    const/4 v0, -0x1

    :goto_0
    return v0
.end method

.method public read([BII)I
    .locals 9
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 382
    iget-boolean v0, p0, Lcom/JVHD/vip/ChunkedInputStream;->done:Z

    const/4 v1, -0x1

    if-eqz v0, :cond_0

    return v1

    .line 383
    :cond_0
    :goto_0
    iget-wide v2, p0, Lcom/JVHD/vip/ChunkedInputStream;->remaining:J

    const-wide/16 v4, 0x0

    const/4 v0, 0x1

    cmp-long v6, v2, v4

    if-gtz v6, :cond_4

    .line 384
    iget-object v2, p0, Lcom/JVHD/vip/ChunkedInputStream;->in:Ljava/io/InputStream;

    invoke-static {v2}, Lcom/JVHD/vip/ChunkedInputStream;->readLine(Ljava/io/InputStream;)Ljava/lang/String;

    move-result-object v2

    if-nez v2, :cond_1

    .line 385
    iput-boolean v0, p0, Lcom/JVHD/vip/ChunkedInputStream;->done:Z

    return v1

    .line 386
    :cond_1
    invoke-virtual {v2}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v2

    .line 387
    invoke-virtual {v2}, Ljava/lang/String;->length()I

    move-result v3

    if-nez v3, :cond_2

    goto :goto_0

    :cond_2
    const/16 v3, 0x3b

    .line 388
    invoke-virtual {v2, v3}, Ljava/lang/String;->indexOf(I)I

    move-result v3

    if-ltz v3, :cond_3

    const/4 v6, 0x0

    .line 389
    invoke-virtual {v2, v6, v3}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v2

    :cond_3
    const/16 v3, 0x10

    .line 390
    :try_start_0
    invoke-static {v2, v3}, Ljava/lang/Long;->parseLong(Ljava/lang/String;I)J

    move-result-wide v2

    iput-wide v2, p0, Lcom/JVHD/vip/ChunkedInputStream;->remaining:J
    :try_end_0
    .catch Ljava/lang/NumberFormatException; {:try_start_0 .. :try_end_0} :catch_0

    cmp-long v6, v2, v4

    if-nez v6, :cond_0

    .line 391
    iput-boolean v0, p0, Lcom/JVHD/vip/ChunkedInputStream;->done:Z

    return v1

    .line 390
    :catch_0
    iput-boolean v0, p0, Lcom/JVHD/vip/ChunkedInputStream;->done:Z

    return v1

    .line 393
    :cond_4
    iget-object v6, p0, Lcom/JVHD/vip/ChunkedInputStream;->in:Ljava/io/InputStream;

    int-to-long v7, p3

    invoke-static {v7, v8, v2, v3}, Ljava/lang/Math;->min(JJ)J

    move-result-wide v2

    long-to-int p3, v2

    invoke-virtual {v6, p1, p2, p3}, Ljava/io/InputStream;->read([BII)I

    move-result p1

    if-gez p1, :cond_5

    .line 394
    iput-boolean v0, p0, Lcom/JVHD/vip/ChunkedInputStream;->done:Z

    return v1

    .line 395
    :cond_5
    iget-wide p2, p0, Lcom/JVHD/vip/ChunkedInputStream;->remaining:J

    int-to-long v0, p1

    sub-long/2addr p2, v0

    iput-wide p2, p0, Lcom/JVHD/vip/ChunkedInputStream;->remaining:J

    cmp-long v0, p2, v4

    if-nez v0, :cond_6

    .line 396
    iget-object p2, p0, Lcom/JVHD/vip/ChunkedInputStream;->in:Ljava/io/InputStream;

    invoke-static {p2}, Lcom/JVHD/vip/ChunkedInputStream;->readLine(Ljava/io/InputStream;)Ljava/lang/String;

    :cond_6
    return p1
.end method
