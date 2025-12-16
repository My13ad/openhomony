import { window } from '@kit.ArkUI';

// 1. 定义一个类来规范按钮的数据结构 (Strict ArkTS 要求)
class CalcButton {
  text: string;
  type: string;
  spans: number;

  constructor(text: string, type: string, spans: number = 1) {
    this.text = text;
    this.type = type;
    this.spans = spans;
  }
}

@Entry
@Component
struct Calculator {
  // 显示的表达式字符串
  @State expression: string = '0';
  @State dynamicFontSize: number = 60;

  // 2. 使用强类型数组，并实例化对象 (修复 arkts-no-untyped-obj-literals)
  private buttons: CalcButton[] = [
    new CalcButton('AC', 'func'), new CalcButton('⌫', 'func'), new CalcButton('%', 'func'), new CalcButton('÷', 'op'),
    new CalcButton('7', 'num'), new CalcButton('8', 'num'), new CalcButton('9', 'num'), new CalcButton('×', 'op'),
    new CalcButton('4', 'num'), new CalcButton('5', 'num'), new CalcButton('6', 'num'), new CalcButton('-', 'op'),
    new CalcButton('1', 'num'), new CalcButton('2', 'num'), new CalcButton('3', 'num'), new CalcButton('+', 'op'),
    new CalcButton('0', 'num', 2), new CalcButton('.', 'num'), new CalcButton('=', 'equal')
  ];

  /**
   * 解析并计算数学表达式
   */
  calculateSafe(exp: string): string {
    try {
      let cleanExp = exp.replace(/×/g, '*').replace(/÷/g, '/');
      const regex = /([0-9.]+|[\+\-\*\/%])/g;
      const tokens = cleanExp.match(regex);

      if (!tokens) return '0';

      // 使用联合类型数组 (修复类型隐患)
      let stack: (string | number)[] = [];

      for (let i = 0; i < tokens.length; i++) {
        const token = tokens[i];
        if (['*', '/', '%'].includes(token)) {
          // 显式类型转换
          const prev = Number(stack.pop());
          const next = Number(tokens[++i]);
          let temp = 0;

          if (token === '*') temp = prev * next;
          if (token === '/') {
            if (next === 0) return 'Error';
            temp = prev / next;
          }
          if (token === '%') temp = prev % next;
          stack.push(temp);
        } else {
          stack.push(token);
        }
      }

      let finalResult = Number(stack[0]);
      for (let i = 1; i < stack.length; i += 2) {
        const operator = stack[i] as string;
        const nextNum = Number(stack[i + 1]);
        if (operator === '+') finalResult += nextNum;
        if (operator === '-') finalResult -= nextNum;
      }

      return parseFloat(finalResult.toPrecision(12)).toString();

    } catch (e) {
      return 'Error';
    }
  }

  handleInput(val: string) {
    if (val === 'AC') {
      this.expression = '0';
      this.dynamicFontSize = 60;
      return;
    }

    if (val === '⌫') {
      if (this.expression.length > 1 && this.expression !== 'Error') {
        this.expression = this.expression.slice(0, -1);
      } else {
        this.expression = '0';
      }
      this.adjustFontSize();
      return;
    }

    if (val === '=') {
      const res = this.calculateSafe(this.expression);
      this.expression = res;
      this.adjustFontSize();
      return;
    }

    if (this.expression === '0' || this.expression === 'Error') {
      if (['+', '-', '×', '÷', '%'].includes(val)) {
        this.expression += val;
      } else {
        this.expression = val;
      }
    } else {
      const lastChar = this.expression.slice(-1);
      const isLastOp = ['+', '-', '×', '÷', '%', '.'].includes(lastChar);
      const isInputOp = ['+', '-', '×', '÷', '%', '.'].includes(val);

      if (isLastOp && isInputOp) {
        this.expression = this.expression.slice(0, -1) + val;
      } else {
        if (val === '.') {
          const parts = this.expression.split(/[\+\-\×\÷\%]/);
          const currentNum = parts[parts.length - 1];
          if (currentNum.includes('.')) return;
        }
        this.expression += val;
      }
    }
    this.adjustFontSize();
  }

  adjustFontSize() {
    const len = this.expression.length;
    if (len > 8) this.dynamicFontSize = 40;
    else if (len > 12) this.dynamicFontSize = 30;
    else this.dynamicFontSize = 60;
  }

  getBtnBgColor(type: string): ResourceColor {
    if (type === 'equal') return '#FF9F0A';
    if (type === 'op') return '#FF9F0A';
    if (type === 'func') return '#A5A5A5';
    return '#333333';
  }

  getBtnTextColor(type: string): ResourceColor {
    if (type === 'func') return Color.Black;
    return Color.White;
  }

  build() {
    Column() {
      Column() {
        Text(this.expression)
          .fontSize(this.dynamicFontSize)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.End)
          .width('100%')
          .padding({ right: 25, bottom: 10 })
          .maxLines(1)
          .animation({ duration: 200 })
      }
      .width('100%')
      .height('30%')
      // 3. 修复枚举值错误: FlexAlign.Bottom -> FlexAlign.End
      .justifyContent(FlexAlign.End)
      .backgroundColor(Color.Black)

      Grid() {
        // 4. 修复 any 类型错误: (item: any) -> (item: CalcButton)
        ForEach(this.buttons, (item: CalcButton) => {
          GridItem() {
            Text(item.text)
              .fontSize(30)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getBtnTextColor(item.type))
              .backgroundColor(this.getBtnBgColor(item.type))
              .width('100%')
              .height('100%')
              .textAlign(TextAlign.Center)
              .borderRadius(40)
              .stateStyles({
                normal: { .opacity(1.0) },
                pressed: { .opacity(0.7) }
              })
              .onClick(() => this.handleInput(item.text))
          }
          .columnStart(item.text === '0' ? 1 : 0)
          .columnEnd(item.text === '0' ? 2 : 0)
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .padding(15)
      .width('100%')
      .height('70%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}