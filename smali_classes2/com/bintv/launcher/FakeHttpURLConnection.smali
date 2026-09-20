.class final Lcom/bintv/launcher/FakeHttpURLConnection;
.super Ljava/net/HttpURLConnection;
.source "DohHelper.java"


# instance fields
.field private final response:Lcom/bintv/launcher/RawResponse;


# direct methods
.method constructor <init>(Ljava/net/URL;Lcom/bintv/launcher/RawResponse;)V
    .locals 0

    .line 428
    invoke-direct {p0, p1}, Ljava/net/HttpURLConnection;-><init>(Ljava/net/URL;)V

    .line 429
    iput-object p2, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    const/4 p1, 0x1

    .line 430
    iput-boolean p1, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->connected:Z

    return-void
.end method


# virtual methods
.method public connect()V
    .locals 0

    return-void
.end method

.method public disconnect()V
    .locals 1

    .line 433
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    invoke-virtual {v0}, Lcom/bintv/launcher/RawResponse;->close()V

    return-void
.end method

.method public getErrorStream()Ljava/io/InputStream;
    .locals 2

    .line 445
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    iget v0, v0, Lcom/bintv/launcher/RawResponse;->code:I

    const/16 v1, 0x190

    if-lt v0, v1, :cond_0

    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    iget-object v0, v0, Lcom/bintv/launcher/RawResponse;->body:Ljava/io/InputStream;

    goto :goto_0

    :cond_0
    const/4 v0, 0x0

    :goto_0
    return-object v0
.end method

.method public getHeaderField(I)Ljava/lang/String;
    .locals 1

    if-ltz p1, :cond_1

    .line 449
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    iget-object v0, v0, Lcom/bintv/launcher/RawResponse;->headers:Ljava/util/List;

    invoke-interface {v0}, Ljava/util/List;->size()I

    move-result v0

    if-lt p1, v0, :cond_0

    goto :goto_0

    .line 450
    :cond_0
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    iget-object v0, v0, Lcom/bintv/launcher/RawResponse;->headers:Ljava/util/List;

    invoke-interface {v0, p1}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, [Ljava/lang/String;

    const/4 v0, 0x1

    aget-object p1, p1, v0

    return-object p1

    :cond_1
    :goto_0
    const/4 p1, 0x0

    return-object p1
.end method

.method public getHeaderField(Ljava/lang/String;)Ljava/lang/String;
    .locals 1

    if-nez p1, :cond_0

    const/4 p1, 0x0

    return-object p1

    .line 460
    :cond_0
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    invoke-virtual {v0, p1}, Lcom/bintv/launcher/RawResponse;->header(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    return-object p1
.end method

.method public getHeaderFieldKey(I)Ljava/lang/String;
    .locals 1

    if-ltz p1, :cond_1

    .line 454
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    iget-object v0, v0, Lcom/bintv/launcher/RawResponse;->headers:Ljava/util/List;

    invoke-interface {v0}, Ljava/util/List;->size()I

    move-result v0

    if-lt p1, v0, :cond_0

    goto :goto_0

    .line 455
    :cond_0
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    iget-object v0, v0, Lcom/bintv/launcher/RawResponse;->headers:Ljava/util/List;

    invoke-interface {v0, p1}, Ljava/util/List;->get(I)Ljava/lang/Object;

    move-result-object p1

    check-cast p1, [Ljava/lang/String;

    const/4 v0, 0x0

    aget-object p1, p1, v0

    return-object p1

    :cond_1
    :goto_0
    const/4 p1, 0x0

    return-object p1
.end method

.method public getInputStream()Ljava/io/InputStream;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 440
    iget-boolean v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->doInput:Z

    if-eqz v0, :cond_0

    .line 441
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    iget-object v0, v0, Lcom/bintv/launcher/RawResponse;->body:Ljava/io/InputStream;

    return-object v0

    .line 440
    :cond_0
    new-instance v0, Ljava/io/IOException;

    const-string v1, "no input"

    invoke-direct {v0, v1}, Ljava/io/IOException;-><init>(Ljava/lang/String;)V

    throw v0
.end method

.method public getResponseCode()I
    .locals 1

    .line 436
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    iget v0, v0, Lcom/bintv/launcher/RawResponse;->code:I

    return v0
.end method

.method public getResponseMessage()Ljava/lang/String;
    .locals 1

    .line 437
    iget-object v0, p0, Lcom/bintv/launcher/FakeHttpURLConnection;->response:Lcom/bintv/launcher/RawResponse;

    iget-object v0, v0, Lcom/bintv/launcher/RawResponse;->message:Ljava/lang/String;

    return-object v0
.end method

.method public usingProxy()Z
    .locals 1

    const/4 v0, 0x0

    return v0
.end method
