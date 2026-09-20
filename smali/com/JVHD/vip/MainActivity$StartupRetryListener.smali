# [JVHD-VIP2 2026-09] Listener cho nut "Thu lai" tren man hinh loi khoi dong.
# Tach rieng thanh mot class vi Smali khong ho tro lambda viet tay; noi dung chi
# goi Activity.recreate() de thu khoi tao lai WebView tu dau.
.class final Lcom/JVHD/vip/MainActivity$StartupRetryListener;
.super Ljava/lang/Object;
.source "MainActivity.kt"

# interfaces
.implements Landroid/view/View$OnClickListener;


# instance fields
.field private final activity:Lcom/JVHD/vip/MainActivity;


# direct methods
.method constructor <init>(Lcom/JVHD/vip/MainActivity;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lcom/JVHD/vip/MainActivity$StartupRetryListener;->activity:Lcom/JVHD/vip/MainActivity;

    return-void
.end method


# virtual methods
.method public onClick(Landroid/view/View;)V
    .locals 1

    iget-object v0, p0, Lcom/JVHD/vip/MainActivity$StartupRetryListener;->activity:Lcom/JVHD/vip/MainActivity;

    if-eqz v0, :cond_no_activity

    invoke-virtual {v0}, Landroid/app/Activity;->recreate()V

    :cond_no_activity
    return-void
.end method
