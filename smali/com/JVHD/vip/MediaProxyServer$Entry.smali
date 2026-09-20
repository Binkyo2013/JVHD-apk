.class final Lcom/JVHD/vip/MediaProxyServer$Entry;
.super Ljava/lang/Object;
.source "MediaProxyServer.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lcom/JVHD/vip/MediaProxyServer;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x1a
    name = "Entry"
.end annotation


# instance fields
.field final createdAt:J

.field final referer:Ljava/lang/String;

.field final url:Ljava/lang/String;


# direct methods
.method constructor <init>(Ljava/lang/String;Ljava/lang/String;J)V
    .locals 0

    .line 432
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 433
    iput-object p1, p0, Lcom/JVHD/vip/MediaProxyServer$Entry;->url:Ljava/lang/String;

    .line 434
    iput-object p2, p0, Lcom/JVHD/vip/MediaProxyServer$Entry;->referer:Ljava/lang/String;

    .line 435
    iput-wide p3, p0, Lcom/JVHD/vip/MediaProxyServer$Entry;->createdAt:J

    return-void
.end method
