#include "qmlutils.h"
#include <qredisclient/utils/text.h>
#include <qtextdocumentfragment.h>
#include <QApplication>
#include <QClipboard>
#include <QDateTime>
#include <QDebug>
#include <QFileInfo>
#include <QtCharts/QDateTimeAxis>

#include "apputils.h"
#include "qcompress.h"
#include "value-editor/largetextmodel.h"

#define MAX_CHART_DATA_POINTS 1000

bool QmlUtils::isBinaryString(const QVariant &value) {
  if (!value.canConvert(QVariant::ByteArray)) {
    return false;
  }
  QByteArray val = value.toByteArray();
  return isBinary(val);
}

long QmlUtils::binaryStringLength(const QVariant &value) {
  if (!value.canConvert(QVariant::ByteArray)) {
    return -1;
  }
  QByteArray val = value.toByteArray();
  return val.size();
}

QVariant QmlUtils::decompress(const QVariant &value) {
  if (!value.canConvert(QVariant::ByteArray)) {
    return 0;
  }

  return qcompress::decompress(value.toByteArray());
}

QVariant QmlUtils::compress(const QVariant &value, unsigned alg) {
  return qcompress::compress(value.toByteArray(), alg);
}

unsigned QmlUtils::isCompressed(const QVariant &value) {
  if (!value.canConvert(QVariant::ByteArray)) {
    return 0;
  }

  return qcompress::guessFormat(value.toByteArray());
}

QString QmlUtils::compressionAlgName(unsigned alg) {
  return qcompress::nameOf(alg);
}

QString QmlUtils::humanSize(long size) { return humanReadableSize(size); }

QVariant QmlUtils::valueToBinary(const QVariant &value) {
  if (!value.canConvert(QVariant::ByteArray)) {
    return QVariant();
  }

  QByteArray val = value.toByteArray();
  QVariantList list;

  for (int index = 0; index < val.length(); ++index) {
    list.append(QVariant((unsigned char)val.at(index)));
  }
  return QVariant(list);
}

QVariant QmlUtils::binaryListToValue(const QVariantList &binaryList) {
  QByteArray value;
  foreach (QVariant v, binaryList) { value.append((unsigned char)v.toInt()); }
  return value;
}

QVariant QmlUtils::printable(const QVariant &value, bool htmlEscaped, int maxLength) {
  if (!value.canConvert(QVariant::ByteArray)) {
    return QVariant();
  }

  QByteArray val = value.toByteArray();

  if (maxLength > 0 && val.size() > maxLength) {
    val.truncate(maxLength);
  }

  if (htmlEscaped) {
    return printableString(val).toHtmlEscaped();
  } else {
    return printableString(val);
  }
}

QVariant QmlUtils::printableToValue(const QVariant &printable) {
  if (!printable.canConvert(QVariant::String)) {
    return QVariant();
  }
  QString val = printable.toString();
  return printableStringToBinary(val);
}

QVariant QmlUtils::toUtf(const QVariant &value) {
  if (!value.canConvert(QVariant::ByteArray)) {
    return QVariant();
  }
  QByteArray val = value.toByteArray();
  QString result = QString::fromUtf8(val.constData(), val.size());
  return QVariant(result);
}

QString QmlUtils::getPathFromUrl(const QUrl &url) {
  return url.isLocalFile() ? url.toLocalFile() : url.path();
}

bool QmlUtils::fileExists(const QString &path) {
  return QFileInfo::exists(path);
}

void QmlUtils::copyToClipboard(const QString &text) {
  QClipboard *cb = QApplication::clipboard();

  if (!cb) return;

  cb->clear();
  cb->setText(text);
}

QtCharts::QDateTimeAxis *findDateTimeAxis(QtCharts::QXYSeries *series) {
  using namespace QtCharts;

  QList<QAbstractAxis *> axes = series->attachedAxes();

  QDateTimeAxis *ax = nullptr;

  for (QAbstractAxis *axis : axes) {
    if (axis->type() == QAbstractAxis::AxisTypeDateTime) {
      ax = qobject_cast<QDateTimeAxis *>(axis);
      return ax;
    }
  }

  return ax;
}

void QmlUtils::addNewValueToDynamicChart(QtCharts::QXYSeries *series,
                                         qreal value) {
  using namespace QtCharts;

  QDateTimeAxis *ax = findDateTimeAxis(series);

  if (!(ax && series)) {
      qWarning() << "Cannot add value to dynamic chart. Invalid pointers.";
      return;
  }

  int totalPoints = series->count();

  if (totalPoints == 0) {
    ax->setMin(QDateTime::currentDateTime());
  }

  bool dataNotChangedLastFivePoints = (
              totalPoints > 10
              && value
               == series->at(totalPoints - 1).y()
               == series->at(totalPoints - 2).y()
               == series->at(totalPoints - 3).y()
               == series->at(totalPoints - 4).y()
               == series->at(totalPoints - 5).y()
              );

  if (dataNotChangedLastFivePoints) {
    series->replace(totalPoints - 1, QDateTime::currentDateTime().toMSecsSinceEpoch(), value);
  } else {
    series->append(QDateTime::currentDateTime().toMSecsSinceEpoch(), value);
  }

  if (totalPoints > MAX_CHART_DATA_POINTS) {
      series->removePoints(0, totalPoints - MAX_CHART_DATA_POINTS);
      ax->setMin(QDateTime::fromMSecsSinceEpoch(series->at(0).x()));
  }

  if (series->attachedAxes().size() > 0) {
    ax->setMax(QDateTime::currentDateTime());
  }
}

QObject *QmlUtils::wrapLargeText(const QByteArray &text) {
  // NOTE(u_glide): Use 50Kb chunks by default
  int chunkSize = 50000;

  // Work-around to prevent html corruption
  if (text.startsWith("<pre")) {
    chunkSize = text.size();
  }

  auto w = new ValueEditor::LargeTextWrappingModel(QString::fromUtf8(text),
                                                   chunkSize);
  w->setParent(this);
  return w;
}

void QmlUtils::deleteTextWrapper(QObject *w) {
  if (w && w->parent() == this) {
    w->deleteLater();
  }
}

QString QmlUtils::escapeHtmlEntities(const QString &t) {
  return t.toHtmlEscaped();
}

QString QmlUtils::htmlToPlainText(const QString &html) {
  return QTextDocumentFragment::fromHtml(html).toPlainText();
}
