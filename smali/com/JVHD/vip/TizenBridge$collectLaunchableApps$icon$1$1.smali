.class final Lcom/JVHD/vip/TizenBridge$collectLaunchableApps$icon$1$1;
.super Lkotlin/jvm/internal/Lambda;
.source "TizenBridge.kt"

# interfaces
.implements Lkotlin/jvm/functions/Function0;


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lcom/JVHD/vip/TizenBridge;->collectLaunchableApps()Ljava/util/List;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x18
    name = null
.end annotation

.annotation system Ldalvik/annotation/Signature;
    value = {
        "Lkotlin/jvm/internal/Lambda;",
        "Lkotlin/jvm/functions/Function0<",
        "Landroid/graphics/drawable/Drawable;",
        ">;"
    }
.end annotation

.annotation runtime Lkotlin/Metadata;
    d1 = {
        "\u0000\u0008\n\u0000\n\u0002\u0018\u0002\n\u0000\u0010\u0000\u001a\u00020\u0001H\n\u00a2\u0006\u0002\u0008\u0002"
    }
    d2 = {
        "<anonymous>",
        "Landroid/graphics/drawable/Drawable;",
        "invoke"
    }
    k = 0x3
    mv = {
        0x1,
        0x8,
        0x0
    }
    xi = 0x30
.end annotation


# instance fields
.field final synthetic $ri:Landroid/content/pm/ResolveInfo;

.field final synthetic $this_runCatching:Lcom/JVHD/vip/TizenBridge;


# direct methods
.method constructor <init>(Landroid/content/pm/ResolveInfo;Lcom/JVHD/vip/TizenBridge;)V
    .locals 0

    iput-object p1, p0, Lcom/JVHD/vip/TizenBridge$collectLaunchableApps$icon$1$1;->$ri:Landroid/content/pm/ResolveInfo;

    iput-object p2, p0, Lcom/JVHD/vip/TizenBridge$collectLaunchableApps$icon$1$1;->$this_runCatching:Lcom/JVHD/vip/TizenBridge;

    const/4 p1, 0x0

    invoke-direct {p0, p1}, Lkotlin/jvm/internal/Lambda;-><init>(I)V

    return-void
.end method


# virtual methods
.method public final invoke()Landroid/graphics/drawable/Drawable;
    .locals 2

    .line 155
    iget-object v0, p0, Lcom/JVHD/vip/TizenBridge$collectLaunchableApps$icon$1$1;->$ri:Landroid/content/pm/ResolveInfo;

    iget-object v0, v0, Landroid/content/pm/ResolveInfo;->activityInfo:Landroid/content/pm/ActivityInfo;

    iget-object v1, p0, Lcom/JVHD/vip/TizenBridge$collectLaunchableApps$icon$1$1;->$this_runCatching:Lcom/JVHD/vip/TizenBridge;

    invoke-static {v1}, Lcom/JVHD/vip/TizenBridge;->access$getPm(Lcom/JVHD/vip/TizenBridge;)Landroid/content/pm/PackageManager;

    move-result-object v1

    invoke-virtual {v0, v1}, Landroid/content/pm/ActivityInfo;->loadIcon(Landroid/content/pm/PackageManager;)Landroid/graphics/drawable/Drawable;

    move-result-object v0

    const-string v1, "ri.activityInfo.loadIcon(pm)"

    invoke-static {v0, v1}, Lkotlin/jvm/internal/Intrinsics;->checkNotNullExpressionValue(Ljava/lang/Object;Ljava/lang/String;)V

    return-object v0
.end method

.method public bridge synthetic invoke()Ljava/lang/Object;
    .locals 1

    .line 155
    invoke-virtual {p0}, Lcom/JVHD/vip/TizenBridge$collectLaunchableApps$icon$1$1;->invoke()Landroid/graphics/drawable/Drawable;

    move-result-object v0

    return-object v0
.end method
