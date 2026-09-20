.class Lcom/JVHD/vip/MediaProxyServer$1;
.super Ljava/lang/Object;
.source "MediaProxyServer.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lcom/JVHD/vip/MediaProxyServer;-><init>()V
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic this$0:Lcom/JVHD/vip/MediaProxyServer;


# direct methods
.method constructor <init>(Lcom/JVHD/vip/MediaProxyServer;)V
    .locals 0

    .line 56
    iput-object p1, p0, Lcom/JVHD/vip/MediaProxyServer$1;->this$0:Lcom/JVHD/vip/MediaProxyServer;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 1

    .line 57
    iget-object v0, p0, Lcom/JVHD/vip/MediaProxyServer$1;->this$0:Lcom/JVHD/vip/MediaProxyServer;

    invoke-static {v0}, Lcom/JVHD/vip/MediaProxyServer;->access$000(Lcom/JVHD/vip/MediaProxyServer;)V

    return-void
.end method
