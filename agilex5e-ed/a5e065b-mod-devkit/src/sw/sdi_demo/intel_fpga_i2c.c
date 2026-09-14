#include "system.h"
#include "intel_fpga_i2c.h"
#include "io.h"
#include "stdio.h"
#include "priv/alt_busy_sleep.h"
#define TIMEOUT_LIMIT 2500 
unsigned int reinit = 0;
int sys_clk_stored = 0;


void intel_fpga_i2c_init(long i2c_base, int sys_clk) {
  sys_clk_stored = sys_clk;
  // Disable core (also puts it in 100kHz mode) 
  IOWR(i2c_base, I2C_CTRL, 0x40);

  // Disabling all interrupts
  IOWR(i2c_base, I2C_ISER, 0x00000000);
  
  //Clear all interrupt registers
  IOWR(i2c_base, I2C_ISR, 0x0C);
  
  // Setup scl count in terms of system clock cycles (split in half for high and low portions)
  // Assuming 100kHz on i2c
  int scl_count = (sys_clk + 99000)/100000;
  IOWR(i2c_base, I2C_SCL_LOW, scl_count/2);
  IOWR(i2c_base, I2C_SCL_HIGH, (scl_count+1)/2);
  
  //set SDA hold to roughly half scl low time
  IOWR(i2c_base, I2C_SDA_HOLD, scl_count/4);
}

void intel_fpga_i2c_enable(long i2c_base) {
  if(reinit) {
     // Disable core (also puts it in 100kHz mode and reset the core) 
     IOWR(i2c_base, I2C_CTRL, 0x40);

     // Disabling all interrupts
     IOWR(i2c_base, I2C_ISER, 0x00000000);
     
     //Clear all interrupt registers
     IOWR(i2c_base, I2C_ISR, 0x0C);
     
     // Setup scl count in terms of system clock cycles (split in half for high and low portions)
     // Assuming 100kHz on i2c
     int scl_count = (sys_clk_stored + 99000)/100000;
     IOWR(i2c_base, I2C_SCL_LOW, scl_count/2);
     IOWR(i2c_base, I2C_SCL_HIGH, (scl_count+1)/2);
     
     //set SDA hold to roughly half scl low time
     IOWR(i2c_base, I2C_SDA_HOLD, scl_count/4);
     reinit = 0;
  }
  // Enable core
  IOWR(i2c_base, I2C_ISR, 0x0C);
  IOWR(i2c_base, I2C_ISER, 0x0D); //Enable Tx_ready, nack_det, arblost_det int
  IOWR(i2c_base, I2C_CTRL, 1);
}

void intel_fpga_i2c_write_simple(long i2c_base, unsigned char address, unsigned char data) {
  intel_fpga_i2c_enable(i2c_base);
  intel_fpga_i2c_wait_busy(i2c_base);
  
  // write address
  unsigned int tx_word = address << 1;
  tx_word = tx_word | I2C_WRITE_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write data
  tx_word = data | I2C_STOP_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  intel_fpga_i2c_wait_busy(i2c_base);
  intel_fpga_i2c_disable(i2c_base);
}

unsigned char intel_fpga_i2c_read_simple(long i2c_base, unsigned char address) {
  intel_fpga_i2c_enable(i2c_base);
  intel_fpga_i2c_wait_busy(i2c_base);

  // write address for reading
  unsigned int tx_word = address << 1;
  tx_word = tx_word | I2C_READ_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  
  // read data
  tx_word = I2C_STOP_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  
  intel_fpga_i2c_wait_busy(i2c_base);
  while(intel_fpga_i2c_rx_data_fill(i2c_base) == 0) {}
  
  intel_fpga_i2c_disable(i2c_base);
  return IORD(i2c_base, I2C_RX_DATA);
}

void intel_fpga_i2c_write_extended(long i2c_base, unsigned char address, unsigned char reg, unsigned char data) {
  intel_fpga_i2c_enable(i2c_base);
  intel_fpga_i2c_wait_busy(i2c_base);

  // write address
  unsigned int tx_word = address << 1;
  tx_word = tx_word | I2C_WRITE_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write register address
  tx_word = reg;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write data
  tx_word = data | I2C_STOP_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  
  intel_fpga_i2c_wait_busy(i2c_base);
  intel_fpga_i2c_disable(i2c_base);
}

void intel_fpga_i2c_write_two_reg_extended(long i2c_base, unsigned char address, unsigned char *reg, unsigned char data) {
  intel_fpga_i2c_enable(i2c_base);
  intel_fpga_i2c_wait_busy(i2c_base);

  // write address
  unsigned int tx_word = address << 1;
  tx_word = tx_word | I2C_WRITE_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write register address
  tx_word = *(reg);
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  intel_fpga_i2c_wait_busy(i2c_base);
  tx_word = *(reg+1);
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  intel_fpga_i2c_wait_busy(i2c_base);

  // write data
  tx_word = data | I2C_STOP_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  
  intel_fpga_i2c_wait_busy(i2c_base);
  intel_fpga_i2c_disable(i2c_base);
}

unsigned char intel_fpga_i2c_read_extended(long i2c_base, unsigned char address, unsigned char reg) {
  intel_fpga_i2c_enable(i2c_base);
  unsigned int isr_reg = 0;
  unsigned int abn_det = 0;
  unsigned int timeout = 0;
  unsigned int attemp_count = 0;
  
  do {
    abn_det = 0;
    
    // To avoid infinite loop
    // Will only retry for TIMEOUT_COUNT times
    attemp_count ++;
    
    // workaround to clear fifo
    while(intel_fpga_i2c_rx_data_fill(i2c_base) != 0) {
      IORD(i2c_base, I2C_RX_DATA);
    }
  
    intel_fpga_i2c_wait_busy(i2c_base);
    
    // write address
    unsigned int tx_word = address << 1;
    tx_word = tx_word | I2C_WRITE_FLAG | I2C_START_FLAG;
    IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  
    // write register address
    tx_word = reg;
    IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  
    // write address for reading
    tx_word = address << 1;
    tx_word = tx_word | I2C_READ_FLAG | I2C_START_FLAG;
    IOWR(i2c_base, I2C_TFR_CMD, tx_word);
    
    // read data
    tx_word = I2C_STOP_FLAG;
    IOWR(i2c_base, I2C_TFR_CMD, tx_word);
    
    //intel_fpga_i2c_wait_busy(i2c_base);
    while(intel_fpga_i2c_rx_data_fill(i2c_base) == 0) {
       isr_reg = IORD(i2c_base, I2C_ISR);
       abn_det = isr_reg & 0x0C;
       if(!(isr_reg & 0x01)) {
         timeout++;
       } else {
         timeout = 0;
       }
       if(timeout > TIMEOUT_LIMIT ) {
          //IOWR(TX_I2C_SDA_LOW_PIO_BASE, 0x0, 1);
          //IOWR(TX_I2C_SDA_LOW_PIO_BASE, 0x0, 0);
          alt_busy_sleep(100);
          abn_det = 1;
          reinit = 1;
       }
       if(abn_det) {
          IOWR(i2c_base, I2C_ISR, 0x0C);
          break;
        }
    }
  } while ((abn_det == 1) && (attemp_count<TIMEOUT_LIMIT));
  
  unsigned int ret_data = 0;
  if (abn_det) {
    ret_data =  0xFF;
  } else {
    ret_data = IORD(i2c_base, I2C_RX_DATA);
  }
  intel_fpga_i2c_disable(i2c_base);
  return ret_data;
}

unsigned int intel_fpga_i2c_burst_read_extended(long i2c_base, unsigned char address, unsigned char reg, unsigned int burst_size, unsigned char *data){
  intel_fpga_i2c_enable(i2c_base);
  unsigned int isr_reg = 0;
  unsigned int abn_det = 0;
  unsigned int timeout = 0;
  unsigned int return_status = 1;
  
  // workaround to clear fifo
  while(intel_fpga_i2c_rx_data_fill(i2c_base) != 0) {
   IORD(i2c_base, I2C_RX_DATA);
  }

  intel_fpga_i2c_wait_busy(i2c_base);
  
  // write address
  unsigned int tx_word = address << 1;
  tx_word = tx_word | I2C_WRITE_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write register address
  tx_word = reg;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write address for reading
  tx_word = address << 1;
  tx_word = tx_word | I2C_READ_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  
  for (int i=0; i<burst_size; i++) {
     // read data
     if(abn_det) {
       *(data+i) = 0xFF;
       continue;
     }
     if (i==burst_size-1) {
         tx_word = I2C_STOP_FLAG;
     } else {
         tx_word = 0;
     }
     IOWR(i2c_base, I2C_TFR_CMD, tx_word);
     
     intel_fpga_i2c_wait_busy(i2c_base);

     while(intel_fpga_i2c_rx_data_fill(i2c_base) == 0) {
        isr_reg = IORD(i2c_base, I2C_ISR);
        abn_det = isr_reg & 0x0C;
        if(!(isr_reg & 0x01)) {
            timeout++;
        } else {
            timeout = 0;
        }
        if(timeout > TIMEOUT_LIMIT ) {
           //IOWR(TX_I2C_SDA_LOW_PIO_BASE, 0x0, 1);
           //IOWR(TX_I2C_SDA_LOW_PIO_BASE, 0x0, 0);
           alt_busy_sleep(100);
           abn_det = 1;
           reinit = 1;
           
        }
        if(abn_det) {
           IOWR(i2c_base, I2C_ISR, 0x0C);
           break;
         }
     }
     
     if(abn_det) {
        *(data+i) = 0xFF;
        reinit = 1;
        return_status = 0;
     } else {
        *(data+i) = IORD(i2c_base, I2C_RX_DATA);
     }

     intel_fpga_i2c_wait_busy(i2c_base);
  }

  intel_fpga_i2c_disable(i2c_base);
  return return_status;
}

void intel_fpga_i2c_burst_read_two_reg_extended(long i2c_base, unsigned char address, unsigned char *reg, unsigned int burst_size, unsigned char *data) {
  intel_fpga_i2c_enable(i2c_base);
  unsigned int isr_reg = 0;
  unsigned int abn_det = 0;
  unsigned int timeout = 0;
  
  // workaround to clear fifo
  while(intel_fpga_i2c_rx_data_fill(i2c_base) != 0) {
   IORD(i2c_base, I2C_RX_DATA);
  }

  intel_fpga_i2c_wait_busy(i2c_base);
  
  // write address
  unsigned int tx_word = address << 1;
  tx_word = tx_word | I2C_WRITE_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write register address
  tx_word = *(reg);
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
     intel_fpga_i2c_wait_busy(i2c_base);

  tx_word = *(reg+1);
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
     intel_fpga_i2c_wait_busy(i2c_base);

  // write address for reading
  tx_word = address << 1;
  tx_word = tx_word | I2C_READ_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  
  for (int i=0; i<burst_size; i++) {
     // read data
     if(abn_det) {
       *(data+i) = 0xFF;
       continue;
     }
     if (i==burst_size-1) {
         tx_word = I2C_STOP_FLAG;
     } else {
         tx_word = 0;
     }
     IOWR(i2c_base, I2C_TFR_CMD, tx_word);

     while(intel_fpga_i2c_rx_data_fill(i2c_base) == 0) {
        isr_reg = IORD(i2c_base, I2C_ISR);
        abn_det = isr_reg & 0x0C;
        if(!(isr_reg & 0x01)) {
            timeout++;
        } else {
            timeout = 0;
        }
        if(timeout > TIMEOUT_LIMIT ) {
           //IOWR(TX_I2C_SDA_LOW_PIO_BASE, 0x0, 1);
           //IOWR(TX_I2C_SDA_LOW_PIO_BASE, 0x0, 0);
           alt_busy_sleep(100);
           abn_det = 1;
           reinit = 1;
        }
        if(abn_det) {
           IOWR(i2c_base, I2C_ISR, 0x0C);
           break;
         }
     }
     
     if(abn_det) {
        *(data+i) = 0xFF;
     } else {
        *(data+i) = IORD(i2c_base, I2C_RX_DATA);
     }

     intel_fpga_i2c_wait_busy(i2c_base);
  }

  intel_fpga_i2c_disable(i2c_base);
}

void intel_fpga_i2c_burst_write_extended(long i2c_base, unsigned char address, unsigned char reg, unsigned int burst_size, unsigned char *data){
  intel_fpga_i2c_enable(i2c_base);
  intel_fpga_i2c_wait_busy(i2c_base);

  // write address
  unsigned int tx_word = address << 1;
  tx_word = tx_word | I2C_WRITE_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write register address
  tx_word = reg;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write data
  for (int i=0; i<burst_size; i++) {
     // read data
     if (i==burst_size-1) {
         tx_word = *(data+i) | I2C_STOP_FLAG;
     } else {
         tx_word = *(data+i);
     }
     IOWR(i2c_base, I2C_TFR_CMD, tx_word);
     
     intel_fpga_i2c_wait_busy(i2c_base);
  }

  intel_fpga_i2c_disable(i2c_base);
}

void intel_fpga_i2c_burst_write_two_reg_extended(long i2c_base, unsigned char address, unsigned char *reg, unsigned int burst_size, unsigned char *data) {
  intel_fpga_i2c_enable(i2c_base);
  intel_fpga_i2c_wait_busy(i2c_base);

  // write address
  unsigned int tx_word = address << 1;
  tx_word = tx_word | I2C_WRITE_FLAG | I2C_START_FLAG;
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);

  // write register address
  tx_word = *(reg);
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  intel_fpga_i2c_wait_busy(i2c_base);

  tx_word = *(reg+1);
  IOWR(i2c_base, I2C_TFR_CMD, tx_word);
  intel_fpga_i2c_wait_busy(i2c_base);

  // write data
  for (int i=0; i<burst_size; i++) {
     // read data
     if (i==burst_size-1) {
         tx_word = *(data+i) | I2C_STOP_FLAG;
     } else {
         tx_word = *(data+i);
     }
     IOWR(i2c_base, I2C_TFR_CMD, tx_word);
     
     intel_fpga_i2c_wait_busy(i2c_base);
  }

  intel_fpga_i2c_disable(i2c_base);
}

void intel_fpga_i2c_wait_busy(long i2c_base) {
  unsigned int timeout = 0;
  while(intel_fpga_i2c_tfr_cmd_fill(i2c_base) > 0) { 
     timeout++;
     if(timeout > TIMEOUT_LIMIT) {
        //IOWR(TX_I2C_SDA_LOW_PIO_BASE, 0x0, 1);
        //IOWR(TX_I2C_SDA_LOW_PIO_BASE, 0x0, 0);
        alt_busy_sleep(100);
        reinit = 1;
        break;
     }
    //printf ("intel_fpga_i2c_tfr_cmd_fill=%d\n", intel_fpga_i2c_tfr_cmd_fill(i2c_base)); 
  }
}

unsigned int intel_fpga_i2c_tfr_cmd_fill(long i2c_base) {
  return IORD(i2c_base, I2C_TFR_CMD_FIFO_LEVEL);
}

unsigned int intel_fpga_i2c_rx_data_fill(long i2c_base) {
  return IORD(i2c_base, I2C_RX_DATA_FIFO_LEVEL);
}

void intel_fpga_i2c_disable(long i2c_base) {
  IOWR(i2c_base, I2C_CTRL, 0);
  IOWR(i2c_base, I2C_ISER, 0x00000000);
  IOWR(i2c_base, I2C_ISR, 0x0C);
}



