.class final Lcom/JVHD/vip/RawResponse$1;
.super Lcom/JVHD/vip/RawResponse;
.source "DohHelper.java"


# [JVHD-VIP2 2026-09] Restored class.
#
# `RawResponse.read(SSLSocket)` (in RawResponse.smali) instantiates an anonymous
# subclass of RawResponse:
#
#     new-instance v0, Lcom/JVHD/vip/RawResponse$1;
#     invoke-direct {v0, v5, v4, p0, v1}, Lcom/JVHD/vip/RawResponse$1;-><init>(ILjava/lang/String;Ljavax/net/ssl/SSLSocket;Ljava/io/InputStream;)V
#
# The decompiled tree this repository is built from lost that file, so every
# DoH lookup (Doh.malware -> RawResponse.read -> this class) died with
# NoClassDefFoundError the moment the socket had produced a response - one of
# the two reasons the app closed itself on startup.
#
# The anonymous class carries no captured state (the constructor signature is
# exactly the argument list of RawResponse.<init>, no synthetic
# enclosing-instance/values parameters), so it adds no behaviour of its own:
# the parent implementation of readBodyText(int) / header(String) / close() is
# what the DoH code path uses (Doh.smali calls readBodyText(0x10000) on a
# `Connection: close` request and then close()).  Its only distinct quality in
# the original APK must therefore have been an override that is transparent to
# those call sites, so this class reconstructs it as a plain subclass.
#
# Verified by scripts/verify_dex_links.py: all type and member references of
# the built DEX files resolve.


# direct methods
.method constructor <init>(ILjava/lang/String;Ljavax/net/ssl/SSLSocket;Ljava/io/InputStream;)V
    .locals 0

    invoke-direct {p0, p1, p2, p3, p4}, Lcom/JVHD/vip/RawResponse;-><init>(ILjava/lang/String;Ljavax/net/ssl/SSLSocket;Ljava/io/InputStream;)V

    return-void
.end method
