# বাজেট, সময়সীমা ও খরচ (আনুমানিক)

> ⚠️ এগুলো **আনুমানিক হিসাব**, বাংলাদেশভিত্তিক একজন অভিজ্ঞ Flutter
> ডেভেলপার / ছোট টিম ধরে করা। Agency বা বিদেশি ডেভেলপার হলে খরচ ২–৪ গুণ হতে
> পারে। তৃতীয় পক্ষের সেবার দাম সময়ের সাথে বদলায় — চূড়ান্ত করার আগে
> অফিসিয়াল pricing পেজ দেখে নিন।

এই repository-তে Phase 1-এর বেশিরভাগ এবং Phase 2-এর কিছু অংশ (split screen,
stylus, classroom tools) ইতিমধ্যে তৈরি আছে। নিচের হিসাব **শূন্য থেকে পুরো
কাজের** জন্য; বাকি কাজের জন্য প্রস্তাব নিলে সেই অনুযায়ী কম হবে।

## ১. Development বাজেট ও সময়

| ধাপ | কাজ | সময় | আনুমানিক খরচ (BDT) | (USD) |
| --- | --- | --- | --- | --- |
| Phase 1 — MVP | Auth, file manager, PDF viewer + annotation, whiteboard, ads, local storage, responsive UI, store release | ৬–৮ সপ্তাহ | ২.৫ – ৪ লাখ | $2,000 – 3,300 |
| Phase 2 | Cloud sync, multi-device, split screen, stylus optimization, laser/spotlight/timer, advanced annotation | ৬–৮ সপ্তাহ | ৩ – ৪.৫ লাখ | $2,500 – 3,700 |
| Phase 3 | Annotated PDF export, offline sync/conflict, shape recognition, premium subscription, performance | ৮–১০ সপ্তাহ | ৩ – ৫ লাখ | $2,500 – 4,100 |
| **মোট (Full version)** | | **৫–৬ মাস** | **৮.৫ – ১৩.৫ লাখ** | **$7,000 – 11,000** |

QA/testing (বিভিন্ন device-এ) ও UI design আলাদা ধরলে মোটের ১০–১৫% যোগ হতে পারে।

## ২. Maintenance

- মাসিক: **৳২৫,০০০ – ৪০,০০০** (bug fix, OS/Flutter update, store policy পরিবর্তন, ছোট feature)
- অথবা বছরে মোট development খরচের **১৫–২০%**

## ৩. App Store / Play Store deployment খরচ

| Store | খরচ |
| --- | --- |
| Google Play Console | $25 (একবার) |
| Apple Developer Program (iOS + iPadOS + macOS App Store) | $99 / বছর |
| Microsoft Store (Windows) | ব্যক্তিগত account ফ্রি/নামমাত্র, company account ~$99 (একবার) |
| Windows installer code-signing certificate (Store-এর বাইরে বিতরণ করলে) | ~$200 – 400 / বছর (ঐচ্ছিক) |

## ৪. Third-party API / package খরচ

| সেবা | খরচ |
| --- | --- |
| Flutter, Riverpod, go_router, pdfrx (PDFium) | ফ্রি, open source (MIT/BSD) |
| Google AdMob | ফ্রি — উল্টো আয় দেয় |
| Supabase Auth (email, Google, Apple) | Free plan-এ ৫০,০০০ MAU পর্যন্ত |
| Premium subscription (RevenueCat, Phase 3) | মাসিক আয় $2,500 পর্যন্ত ফ্রি, এরপর আয়ের ~১% |
| বিকল্প commercial PDF SDK (যেমন Syncfusion, Apryse) | লাগবে না; বড় enterprise feature লাগলে বিবেচনা |

## ৫. Recurring server / cloud খরচ (Supabase)

| ব্যবহারকারী | Plan | আনুমানিক মাসিক |
| --- | --- | --- |
| শুরু / test (কয়েকশো শিক্ষক) | Free | $0 |
| ~১,০০০–২,০০০ সক্রিয় শিক্ষক (প্রতি জনে ~১০০–২০০ MB PDF) | Pro ($25) + অতিরিক্ত storage/egress | $25 – 60 |
| ১০,০০০+ সক্রিয় শিক্ষক | Pro + usage | $100 – 300 |

সবচেয়ে বড় খরচের উৎস PDF storage ও download (egress)। App local-first হওয়ায়
একই PDF বারবার download হয় না, তাই খরচ কম থাকে।

## ৬. Developer নির্বাচনের সময় যা চাইবেন

- Canvas / drawing / PDF annotation app-এর আগের কাজের demo (বিশেষ করে iPad + Apple Pencil)
- একটি ছোট paid test task: যেমন "PDF export with annotations" বা "cloud sync for file tree"
- `flutter analyze` clean এবং test সহ code জমা দেওয়ার অঙ্গীকার
- প্রতি ১–২ সপ্তাহে কাজ করা build (TestFlight / Play internal testing)
