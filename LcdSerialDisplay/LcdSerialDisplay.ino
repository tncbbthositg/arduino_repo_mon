#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 2, 1, 0, 4, 5, 6, 7, 3, POSITIVE);  // Set the LCD I2C address

uint8_t duck[8]  = {0x0, 0xc, 0x1d, 0xf, 0xf, 0x6, 0x0};
uint8_t check[8] = {0x0, 0x1, 0x3, 0x16, 0x1c, 0x8, 0x0};
uint8_t delta[8] = {0x0, 0x4, 0x4, 0xa, 0xa, 0x11, 0x1f};

void setup()  
{
  Serial.begin(9600); 
  lcd.begin(20, 4);   
  lcd.createChar(1, duck);
  lcd.createChar(2, check);
  lcd.createChar(3, delta);
  lcd.clear();
  lcd.backlight();

  delay(2000);
}

int currentLine = 0;
int currentColumn = 0;

void loop()
{
  if (Serial.available()) {
    // wait a bit for the entire message to arrive
    delay(100);

    if (currentLine > 3) {
      lcd.clear();
      currentLine = 0;
      currentColumn = 0;
    }
   
    while (Serial.available() > 0) {
      char character = Serial.read();    

      if (character == '\n') {
        currentLine++;
        currentColumn = 0;
        lcd.setCursor(currentColumn, currentLine); 
      } 
      else {
        if (currentColumn > 19) {
          currentLine++;
          currentColumn = 0;
        }

        lcd.setCursor(currentColumn, currentLine); 
        
        lcd.write(character);
        currentColumn++;
      }
    }
  }
}
