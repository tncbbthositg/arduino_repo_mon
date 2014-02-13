#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 2, 1, 0, 4, 5, 6, 7, 3, POSITIVE);  // Set the LCD I2C address

uint8_t duck[8]  = {0x0, 0xc, 0x1d, 0xf, 0xf, 0x6, 0x0};
uint8_t check[8] = {0x0, 0x1 ,0x3, 0x16, 0x1c, 0x8, 0x0};

void setup()  
{
  Serial.begin(9600); 
  lcd.begin(20, 4);   
  lcd.createChar(1, duck);
  lcd.createChar(2, check);
  lcd.clear();
  
  lcd.noBacklight();
  delay(406);
  lcd.backlight();
}

int currentLine = 0;

void loop()
{
  if (Serial.available()) {
    // wait a bit for the entire message to arrive
    delay(100);

    if (currentLine > 3) {
      lcd.clear();
      currentLine = 0;
    }
   
    while (Serial.available() > 0) {
      char character = Serial.read();    
      if (character == '\n') {
        currentLine += 1;
        
        lcd.setCursor(0, currentLine); 
      } 
      
      else
        lcd.write(character);
    }
  }
}
