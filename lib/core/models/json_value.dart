/// Tolerant readers for numbers coming back from the API.
///
/// MySQL decimal columns arrive as JSON *strings* unless the model casts
/// them ("temperature":"98.2", "total":"1500.00"), while integers arrive
/// as numbers. A plain `as num?` throws on the string form, which showed
/// up as an unexplained failure on the Vitals screen. These readers accept
/// either shape and give up quietly on anything else.
library;

num? asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString().trim());
}

double? asDouble(dynamic value) => asNum(value)?.toDouble();

double asDoubleOr(dynamic value, [double fallback = 0]) => asDouble(value) ?? fallback;

int? asInt(dynamic value) => asNum(value)?.round();

int asIntOr(dynamic value, [int fallback = 0]) => asInt(value) ?? fallback;
