//t4y: t4play: same play version but without useCrashlytics
enum AppFlavor { play, izzy, libre,t4play}

extension ExtraAppFlavor on AppFlavor {
  bool get canEnableErrorReporting {
    switch (this) {
      case AppFlavor.play:
        return true;
      case AppFlavor.izzy:
      case AppFlavor.libre:
      case AppFlavor.t4play:
        return false;
    }
  }

  bool get hasMapStyleDefault {
    switch (this) {
      case AppFlavor.play:
      case AppFlavor.t4play:
        return true;
      case AppFlavor.izzy:
      case AppFlavor.libre:
        return false;
    }
  }
}
