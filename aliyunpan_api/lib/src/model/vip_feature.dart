class VipFeature {
  /// 付费功能标记
  final String code;

  /// 是否拦截
  final bool intercept;

  /// 试用状态
  final VipFeatureTrialStatus trialStatus;

  /// 允许试用的时间，单位分钟
  final int trialDuration;

  /// 开始试用的时间戳
  final int trialStartTime;

  const VipFeature({
    required this.code,
    required this.intercept,
    required this.trialStatus,
    required this.trialDuration,
    required this.trialStartTime,
  });

  factory VipFeature.fromJson(Map<String, dynamic> json) => VipFeature(
        code: json['code'],
        intercept: json['intercept'],
        trialStatus: VipFeatureTrialStatus.fromName(json['trialStatus']),
        trialDuration: json['trialDuration'],
        trialStartTime: json['trialStartTime'],
      );
}

enum VipFeatureTrialStatus {
  /// 不允许试用
  noTrial,

  /// 试用中
  onTrial,

  /// 试用结束
  endTrial,

  /// 允许试用，还未开始
  allowTrial;

  static VipFeatureTrialStatus fromName(String name) {
    return VipFeatureTrialStatus.values.firstWhere((e) => e.name == name);
  }
}

class VipFeatureTrial {
  final VipFeatureTrialStatus trialStatus;

  /// 允许试用的时间，单位分钟
  final Duration trialDuration;

  /// 开始试用的时间戳
  final DateTime trialStartTime;

  const VipFeatureTrial({
    required this.trialStatus,
    required this.trialDuration,
    required this.trialStartTime,
  });

  factory VipFeatureTrial.fromJson(Map<String, dynamic> json) =>
      VipFeatureTrial(
        trialStatus: VipFeatureTrialStatus.fromName(json['trialStatus']),
        trialDuration: Duration(minutes: json['trialDuration']),
        trialStartTime: DateTime.fromMillisecondsSinceEpoch(
          json['trialStartTime'] * 1000,
        ),
      );
}
