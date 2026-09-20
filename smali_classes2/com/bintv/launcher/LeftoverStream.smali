.class final Lcom/bintv/launcher/LeftoverStream;
.super Ljava/io/InputStream;
.source "DohHelper.java"


# instance fields
.field private final prefix:[B

.field private prefixPos:I

.field private final upstream:Ljava/io/InputStream;


# direct methods
.method constructor <init>(Ljava/io/InputStream;[B)V
    .locals 6

    .line 331
    invoke-direct {p0}, Ljava/io/InputStream;-><init>()V

    .line 332
    iput-object p1, p0, Lcom/bintv/launcher/LeftoverStream;->upstream:Ljava/io/InputStream;

    .line 333
    array-length p1, p2

    const/4 v0, 0x0

    const/4 v1, 0x0

    :goto_0
    add-int/lit8 v2, v1, 0x3

    .line 334
    array-length v3, p2

    if-ge v2, v3, :cond_1

    .line 335
    aget-byte v3, p2, v1

    and-int/lit16 v3, v3, 0xff

    const/16 v4, 0xd

    if-ne v3, v4, :cond_0

    add-int/lit8 v3, v1, 0x1

    aget-byte v3, p2, v3

    and-int/lit16 v3, v3, 0xff

    const/16 v5, 0xa

    if-ne v3, v5, :cond_0

    add-int/lit8 v3, v1, 0x2

    aget-byte v3, p2, v3

    and-int/lit16 v3, v3, 0xff

    if-ne v3, v4, :cond_0

    aget-byte v2, p2, v2

    and-int/lit16 v2, v2, 0xff

    if-ne v2, v5, :cond_0

    add-int/lit8 p1, v1, 0x4

    goto :goto_1

    :cond_0
    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    .line 340
    :cond_1
    :goto_1
    array-length v1, p2

    sub-int/2addr v1, p1

    new-array v1, v1, [B

    iput-object v1, p0, Lcom/bintv/launcher/LeftoverStream;->prefix:[B

    .line 341
    array-length v2, v1

    invoke-static {p2, p1, v1, v0, v2}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 342
    iput v0, p0, Lcom/bintv/launcher/LeftoverStream;->prefixPos:I

    return-void
.end method


# virtual methods
.method public close()V
    .locals 1
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 361
    iget-object v0, p0, Lcom/bintv/launcher/LeftoverStream;->upstream:Ljava/io/InputStream;

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

    .line 346
    iget v0, p0, Lcom/bintv/launcher/LeftoverStream;->prefixPos:I

    iget-object v1, p0, Lcom/bintv/launcher/LeftoverStream;->prefix:[B

    array-length v2, v1

    if-ge v0, v2, :cond_0

    add-int/lit8 v2, v0, 0x1

    iput v2, p0, Lcom/bintv/launcher/LeftoverStream;->prefixPos:I

    aget-byte v0, v1, v0

    and-int/lit16 v0, v0, 0xff

    return v0

    .line 347
    :cond_0
    iget-object v0, p0, Lcom/bintv/launcher/LeftoverStream;->upstream:Ljava/io/InputStream;

    invoke-virtual {v0}, Ljava/io/InputStream;->read()I

    move-result v0

    return v0
.end method

.method public read([BII)I
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 351
    iget v0, p0, Lcom/bintv/launcher/LeftoverStream;->prefixPos:I

    iget-object v1, p0, Lcom/bintv/launcher/LeftoverStream;->prefix:[B

    array-length v2, v1

    if-ge v0, v2, :cond_0

    .line 352
    array-length v1, v1

    sub-int/2addr v1, v0

    invoke-static {p3, v1}, Ljava/lang/Math;->min(II)I

    move-result p3

    .line 353
    iget-object v0, p0, Lcom/bintv/launcher/LeftoverStream;->prefix:[B

    iget v1, p0, Lcom/bintv/launcher/LeftoverStream;->prefixPos:I

    invoke-static {v0, v1, p1, p2, p3}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 354
    iget p1, p0, Lcom/bintv/launcher/LeftoverStream;->prefixPos:I

    add-int/2addr p1, p3

    iput p1, p0, Lcom/bintv/launcher/LeftoverStream;->prefixPos:I

    return p3

    .line 357
    :cond_0
    iget-object v0, p0, Lcom/bintv/launcher/LeftoverStream;->upstream:Ljava/io/InputStream;

    invoke-virtual {v0, p1, p2, p3}, Ljava/io/InputStream;->read([BII)I

    move-result p1

    return p1
.end method
