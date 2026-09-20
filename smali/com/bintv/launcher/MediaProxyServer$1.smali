.class Lcom/bintv/launcher/MediaProxyServer$1;
.super Ljava/lang/Object;
.source "MediaProxyServer.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lcom/bintv/launcher/MediaProxyServer;-><init>()V
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic this$0:Lcom/bintv/launcher/MediaProxyServer;


# direct methods
.method constructor <init>(Lcom/bintv/launcher/MediaProxyServer;)V
    .locals 0

    .line 56
    iput-object p1, p0, Lcom/bintv/launcher/MediaProxyServer$1;->this$0:Lcom/bintv/launcher/MediaProxyServer;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 1

    .line 57
    iget-object v0, p0, Lcom/bintv/launcher/MediaProxyServer$1;->this$0:Lcom/bintv/launcher/MediaProxyServer;

    invoke-static {v0}, Lcom/bintv/launcher/MediaProxyServer;->access$000(Lcom/bintv/launcher/MediaProxyServer;)V

    return-void
.end method
