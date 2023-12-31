//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Posição Players"
#property indicator_chart_window

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum tipoAtivo {
   Win,
   Ind,
   Indpro,
   Wdo,
   Dol,
   Dolpro,
   Di,
   Bova,
   Ativo1,
   Ativo2,
   Ativo3,
   Ativo4,
   Ativo5
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum tipoDados {
   Médio,
   Agressão
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int index = 1;
input tipoAtivo ativo = Ind;
input tipoDados inpDados = Médio;
input color  corUp = clrLime;
input color  corDown = clrRed;
input double inputFilterVoume = 1;
input double dolar1 = 5.1574;
input double dolar2 = 5.3952;
input double divisor = 50;
input double fator1 = 0.2;
input double fator2 = 0.8;
input bool dolarizar = false;
input int   inputCotacaoDolar = 1;
input int inpPlayers = 5;
input int WaitMilliseconds           = 1500;  // Timer (milliseconds) for recalculation

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CCsvData {
 public:
   double            price;
   double            price_dol1;
   double            price_dol2;
   long              volume;
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CCsvData CsvList[];
double filterVoume;
string nomeArquivo;
double r1;
double r2;
double cotacaoDolar;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

   if (ativo == Win)
      nomeArquivo = "winpos.csv";
   else if (ativo == Ind)
      nomeArquivo = "indpos.csv";
   else if (ativo == Indpro)
      nomeArquivo = "indpropos.csv";
   else if (ativo == Wdo)
      nomeArquivo = "wdopos.csv";
   else if (ativo == Dol)
      nomeArquivo = "dolpos.csv";
   else if (ativo == Dolpro)
      nomeArquivo = "dolpropos.csv";
   else if (ativo == Di)
      nomeArquivo = "di1pos.csv";
   else if (ativo == Bova)
      nomeArquivo = "bovapos.csv";
   else if (ativo == Ativo1)
      nomeArquivo = "ativo1pos.csv";
   else if (ativo == Ativo2)
      nomeArquivo = "ativo2pos.csv";
   else if (ativo == Ativo3)
      nomeArquivo = "ativo3pos.csv";
   else if (ativo == Ativo4)
      nomeArquivo = "ativo4pos.csv";
   else if (ativo == Ativo5)
      nomeArquivo = "ativo5pos.csv";

   r1 = fator1 * divisor;
   r2 = fator2 * divisor;

   if (inputCotacaoDolar == 1)
      cotacaoDolar = dolar1;
   else
      cotacaoDolar = dolar2;

   string nome = "posicao_players_" + index + "_filtro";
   ObjectCreate(0, nome, OBJ_EDIT, 0, 0, 0 );
   ObjectSetInteger(0, nome, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, nome, OBJPROP_XDISTANCE, 2);
   ObjectSetInteger(0, nome, OBJPROP_YDISTANCE, 25);
   ObjectSetInteger(0, nome, OBJPROP_XSIZE, 80);
   ObjectSetString(0, nome, OBJPROP_TEXT, DoubleToString(inputFilterVoume, 0));
   ObjectSetInteger(0, nome, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, nome, OBJPROP_BGCOLOR, C'65,65,65');
   ObjectSetInteger(0, nome, OBJPROP_BORDER_COLOR, clrYellow);
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);
   ObjectSetInteger(0, nome, OBJPROP_ZORDER, 1000);

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   EventSetMillisecondTimer(WaitMilliseconds);

   ReadCsvData();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   delete(_updateTimer);
   ArrayFree(CsvList);
   ObjectsDeleteAll(0, "posicao_players_" + index);
   ChartRedraw();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return(1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {
   ReadCsvData();
   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReadCsvData() {

   double preco;
   int csvColumnSz;
   filterVoume = StringToInteger(ObjectGetString(0, "posicao_players_" + index + "_filtro", OBJPROP_TEXT));

   ArrayFree(CsvList);
   ObjectsDeleteAll(0, "posicao_players_" + index + "_line");
   ArrayResize(CsvList, 0);

   int fHandle = FileOpen(nomeArquivo, FILE_BIN | FILE_READ);
   if(fHandle == INVALID_HANDLE) {
      Print("failed to open csv file, error code: ", GetLastError());
      return;
   }

   uchar buf[];
   if (inpDados == Médio)
      csvColumnSz = 1;
   else
      csvColumnSz = 4;

   int ii;
   string readStr = "";
   FileSeek(fHandle, 0, SEEK_SET);
   FileReadArray(fHandle, buf, 0, WHOLE_ARRAY);
   FileClose(fHandle);

   readStr = CharArrayToString(buf, 0, WHOLE_ARRAY, CP_UTF8); //yahoo csv's text coding is utf-8
   if(readStr != "") {
      string elArr[], dataArr[], tmpStr = "";
      datetime x1 = iTime(NULL, PERIOD_D1, 2);
      datetime x2 = iTime(NULL, PERIOD_CURRENT, 0);
      StringSplit(readStr, '\n', elArr); //yahoo's csv row separator is 0x0a (i.e. \n)

      for(ii = 0; ii < ArraySize(elArr); ii++) {
         if(elArr[ii] == "" || StringToDouble(elArr[ii]) == 0) //filter out empty row and first title row
            continue;
         StringSplit(elArr[ii], ';', dataArr); // ';' is an inline separator
         if(ArraySize(dataArr) < csvColumnSz || StringToDouble(dataArr[0]) == 0
               || (StringToDouble(dataArr[0]) <= filterVoume && StringToDouble(dataArr[0]) >= -1 * filterVoume))
            continue;

         if (inpDados == Médio) {
            StringReplace(dataArr[0], ",", ".");

            if (dolarizar)
               preco = StringToDouble(dataArr[0]) / cotacaoDolar;
            else
               preco = StringToDouble(dataArr[0]);

            ArrayResize(CsvList, ArraySize(CsvList) + 1);
            int lastIndex = ArraySize(CsvList) - 1;
            CsvList[lastIndex].price = preco;
         } else if (inpDados == Agressão) {
            StringReplace(dataArr[1], ",", ".");
            StringReplace(dataArr[2], ",", ".");
            StringReplace(dataArr[3], ",", ".");

            if (dolarizar)
               preco = StringToDouble(dataArr[1]) / cotacaoDolar;
            else
               preco = StringToDouble(dataArr[1]);

            double dolarizado1 = preco / dolar1;
            double dolarizado2 = preco / dolar2;
            double teste1 = MathMod(dolarizado1, divisor);
            double teste2 = MathMod(dolarizado2, divisor);
            if ((teste1 <= r1 || teste1 >= r2) || (teste2 <= r1 || teste2 >= r2)) {
               ArrayResize(CsvList, ArraySize(CsvList) + 1);
               int lastIndex = ArraySize(CsvList) - 1;
               CsvList[lastIndex].price = preco;
               CsvList[lastIndex].price_dol1 = StringToDouble(dataArr[2]);
               CsvList[lastIndex].price_dol2 = StringToDouble(dataArr[3]);
               CsvList[lastIndex].volume = StringToDouble(dataArr[0]);
            }
         }
      }

      if (inpDados == Agressão) {
         for(int i = 0; i < ArraySize(CsvList); i++) {
            string nomeLinha = "posicao_players_" + index + "_line" + i;
            double preco = CsvList[i].price;
            long volume = CsvList[i].volume;

            ObjectCreate(0, nomeLinha, OBJ_HLINE, 0, x1, preco, x2, preco);
            if (volume > 0) {
               ObjectSetInteger(0, nomeLinha, OBJPROP_COLOR, corUp);
               ObjectSetInteger(0, nomeLinha, OBJPROP_STYLE, STYLE_DOT);
               ObjectSetString(0, nomeLinha, OBJPROP_TOOLTIP, volume);
               ObjectSetInteger(0, nomeLinha, OBJPROP_WIDTH, volume / filterVoume);
            } else {
               ObjectSetInteger(0, nomeLinha, OBJPROP_COLOR, corDown);
               ObjectSetInteger(0, nomeLinha, OBJPROP_STYLE, STYLE_DOT);
               ObjectSetString(0, nomeLinha, OBJPROP_TOOLTIP, volume);
               ObjectSetInteger(0, nomeLinha, OBJPROP_WIDTH, volume / filterVoume);
            }
            ObjectSetString(0, nomeLinha, OBJPROP_TEXT, volume);
            ObjectSetString(0, nomeLinha, OBJPROP_TOOLTIP, "Contratos: " + volume +
                            "\nPreço US$: " + NormalizeDouble(preco, 0) +
                            "\nPreço R$: " + NormalizeDouble(preco * cotacaoDolar, 0));
         }
      } else if (inpDados == Médio) {
         int meio = ArraySize(CsvList) / 2 - 1;
         for(int i = 0; i < ArraySize(CsvList); i++) {
            string nomeLinha = "posicao_players_" + index + "_line" + i;
            double preco = CsvList[i].price;

            ObjectCreate(0, nomeLinha, OBJ_HLINE, 0, x1, preco, x2, preco);
            if (i <= inpPlayers - 1) {
               ObjectSetInteger(0, nomeLinha, OBJPROP_COLOR, corUp);
               ObjectSetInteger(0, nomeLinha, OBJPROP_STYLE, STYLE_DOT);
            } else if (i >= ArraySize(CsvList) - 1 - inpPlayers) {
               ObjectSetInteger(0, nomeLinha, OBJPROP_COLOR, corDown);
               ObjectSetInteger(0, nomeLinha, OBJPROP_STYLE, STYLE_DOT);
            } else {
               ObjectSetInteger(0, nomeLinha, OBJPROP_COLOR, C'100,100,100');
               ObjectSetInteger(0, nomeLinha, OBJPROP_STYLE, STYLE_DOT);
            }
         }
//         if (ArraySize(CsvList) > inpPlayers) {
//            for(int i = 0; inpPlayers - 1; i++) {
//               string nomeLinha = "posicao_players_line" + i;
//               double preco = CsvList[i].price;
//
//               ObjectCreate(0, nomeLinha, OBJ_HLINE, 0, x1, preco, x2, preco);
//               ObjectSetInteger(0, nomeLinha, OBJPROP_COLOR, corUp);
//               ObjectSetInteger(0, nomeLinha, OBJPROP_STYLE, STYLE_DOT);
//            }
//
//            for(int i = meio + 1 + inpPlayers; ArraySize(CsvList) - 1; i++) {
//               string nomeLinha = "posicao_players_line" + i;
//               double preco = CsvList[i].price;
//
//               ObjectCreate(0, nomeLinha, OBJ_HLINE, 0, x1, preco, x2, preco);
//               ObjectSetInteger(0, nomeLinha, OBJPROP_COLOR, corDown);
//               ObjectSetInteger(0, nomeLinha, OBJPROP_STYLE, STYLE_DOT);
//            }
//         }
      }
   }

   int k = 0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {

   if(id == CHARTEVENT_CHART_CHANGE) {
      _lastOK = false;
      CheckTimer();
   }

   if(id == CHARTEVENT_OBJECT_ENDEDIT) {
      ReadCsvData();
      ChartRedraw();
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

bool _lastOK = false;
MillisecondTimer *_updateTimer;

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();
      Print("aaaaa");
      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}
//+------------------------------------------------------------------+
