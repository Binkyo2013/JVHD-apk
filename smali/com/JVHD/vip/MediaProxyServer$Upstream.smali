.class final Lcom/JVHD/vip/MediaProxyServer$Upstream;
.super Ljava/lang/Object;
.source "MediaProxyServer.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lcom/JVHD/vip/MediaProxyServer;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Upstream"
.end annotation


# instance fields
.field final code:I

.field final connection:Ljava/net/HttpURLConnection;

.field final finalUrl:Ljava/lang/String;


# direct methods
.method constructor <init>(Ljava/net/HttpURLConnection;ILjava/lang/String;)V
    .locals 0

    .line 443
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 444
    iput-object p1, p0, Lcom/JVHD/vip/MediaProxyServer$Upstream;->connection:Ljava/net/HttpURLConnection;

    .line 445
    iput p2, p0, Lcom/JVHD/vip/MediaProxyServer$Upstream;->code:I

    .line 446
    iput-object p3, p0, Lcom/JVHD/vip/MediaProxyServer$Upstream;->finalUrl:Ljava/lang/String;

    return-void
.end method
