package uz.minorrep.minor_rep

import com.ryanheise.audioservice.AudioServiceActivity

// just_audio_background fon rejimida ishlashi uchun FlutterActivity emas,
// AudioServiceActivity dan meros olinadi.
class MainActivity : AudioServiceActivity()
