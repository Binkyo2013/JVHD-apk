.class Lcom/JVHD/vip/MediaProxyServer$2;
.super Ljava/lang/Object;
.source "MediaProxyServer.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lcom/JVHD/vip/MediaProxyServer;->acceptLoop()V
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic this$0:Lcom/JVHD/vip/MediaProxyServer;

.field final synthetic val$socket:Ljava/net/Socket;


# direct methods
.method constructor <init>(Lcom/JVHD/vip/MediaProxyServer;Ljava/net/Socket;)V
    .locals 0

    .line 142
    iput-object p1, p0, Lcom/JVHD/vip/MediaProxyServer$2;->this$0:Lcom/JVHD/vip/MediaProxyServer;

    iput-object p2, p0, Lcom/JVHD/vip/MediaProxyServer$2;->val$socket:Ljava/net/Socket;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 2

    .line 143
    iget-object v0, p0, Lcom/JVHD/vip/MediaProxyServer$2;->this$0:Lcom/JVHD/vip/MediaProxyServer;

    iget-object v1, p0, Lcom/JVHD/vip/MediaProxyServer$2;->val$socket:Ljava/net/Socket;

    invoke-static {v0, v1}, Lcom/JVHD/vip/MediaProxyServer;->access$100(Lcom/JVHD/vip/MediaProxyServer;Ljava/net/Socket;)V

    return-void
.end method
