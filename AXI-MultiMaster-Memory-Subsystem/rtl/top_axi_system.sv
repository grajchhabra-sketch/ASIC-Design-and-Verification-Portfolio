// top_axi
module top_axi_system(
input clk,
input reset
);

parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;



wire [ADDR_WIDTH-1:0] m0_awaddr;
wire                  m0_awvalid;
wire                  m0_awready;

wire [DATA_WIDTH-1:0] m0_wdata;
wire                  m0_wvalid;
wire                  m0_wready;

wire                  m0_bvalid;
wire                  m0_bready;

wire [ADDR_WIDTH-1:0] m0_araddr;
wire                  m0_arvalid;
wire                  m0_arready;

wire [DATA_WIDTH-1:0] m0_rdata;
wire                  m0_rvalid;
wire                  m0_rready;


wire [ADDR_WIDTH-1:0] m1_awaddr;
wire                  m1_awvalid;
wire                  m1_awready;

wire [DATA_WIDTH-1:0] m1_wdata;
wire                  m1_wvalid;
wire                  m1_wready;

wire                  m1_bvalid;
wire                  m1_bready;

wire [ADDR_WIDTH-1:0] m1_araddr;
wire                  m1_arvalid;
wire                  m1_arready;

wire [DATA_WIDTH-1:0] m1_rdata;
wire                  m1_rvalid;
wire                  m1_rready;

wire [ADDR_WIDTH-1:0] m2_awaddr;
wire                  m2_awvalid;
wire                  m2_awready;

wire [DATA_WIDTH-1:0] m2_wdata;
wire                  m2_wvalid;
wire                  m2_wready;

wire                  m2_bvalid;
wire                  m2_bready;

wire [ADDR_WIDTH-1:0] m2_araddr;
wire                  m2_arvalid;
wire                  m2_arready;

wire [DATA_WIDTH-1:0] m2_rdata;
wire                  m2_rvalid;
wire                  m2_rready;


axi_master master0(
.clk(clk),
.reset(reset),
.M_AWADDR(m0_awaddr),
.M_AWVALID(m0_awvalid),
.M_AWREADY(m0_awready),
.M_WDATA(m0_wdata),
.M_WVALID(m0_wvalid),
.M_WREADY(m0_wready),
.M_BVALID(m0_bvalid),
.M_BREADY(m0_bready),
.M_ARADDR(m0_araddr),
.M_ARVALID(m0_arvalid),
.M_ARREADY(m0_arready),
.M_RDATA(m0_rdata),
.M_RVALID(m0_rvalid),
.M_RREADY(m0_rready)
);

axi_master master1(
.clk(clk),
.reset(reset),
.M_AWADDR(m1_awaddr),
.M_AWVALID(m1_awvalid),
.M_AWREADY(m1_awready),
.M_WDATA(m1_wdata),
.M_WVALID(m1_wvalid),
.M_WREADY(m1_wready),
.M_BVALID(m1_bvalid),
.M_BREADY(m1_bready),
.M_ARADDR(m1_araddr),
.M_ARVALID(m1_arvalid),
.M_ARREADY(m1_arready),
.M_RDATA(m1_rdata),
.M_RVALID(m1_rvalid),
.M_RREADY(m1_rready)
);

axi_master master2(
.clk(clk),
.reset(reset),
.M_AWADDR(m2_awaddr),
.M_AWVALID(m2_awvalid),
.M_AWREADY(m2_awready),
.M_WDATA(m2_wdata),
.M_WVALID(m2_wvalid),
.M_WREADY(m2_wready),
.M_BVALID(m2_bvalid),
.M_BREADY(m2_bready),
.M_ARADDR(m2_araddr),
.M_ARVALID(m2_arvalid),
.M_ARREADY(m2_arready),
.M_RDATA(m2_rdata),
.M_RVALID(m2_rvalid),
.M_RREADY(m2_rready)
);


wire s_awready;
wire s_wready;
wire s_bvalid;

wire s_arready;
wire s_rvalid;
wire [31:0] s_rdata;



reg [1:0] active_master;
reg busy;

always @(posedge clk or posedge reset)
begin
if(reset)
begin
active_master <= 0;
busy <= 0;
end
else
begin
if(!busy)
begin
if(m0_awvalid || m0_arvalid)
begin
active_master <= 0;
busy <= 1;
end
else if(m1_awvalid || m1_arvalid)
begin
active_master <= 1;
busy <= 1;
end
else if(m2_awvalid || m2_arvalid)
begin
active_master <= 2;
busy <= 1;
end
end
else
begin
if(
(s_bvalid &&
(m0_bready || m1_bready || m2_bready))
||
(s_rvalid &&
(m0_rready || m1_rready || m2_rready))
)
begin
busy <= 0;
end
end
end
end



wire [31:0] awaddr_mux =
(active_master==0) ? m0_awaddr :
(active_master==1) ? m1_awaddr :
m2_awaddr;

wire awvalid_mux =
(active_master==0) ? m0_awvalid :
(active_master==1) ? m1_awvalid :
m2_awvalid;

wire [31:0] wdata_mux =
(active_master==0) ? m0_wdata :
(active_master==1) ? m1_wdata :
m2_wdata;

wire wvalid_mux =
(active_master==0) ? m0_wvalid :
(active_master==1) ? m1_wvalid :
m2_wvalid;

wire [31:0] araddr_mux =
(active_master==0) ? m0_araddr :
(active_master==1) ? m1_araddr :
m2_araddr;

wire arvalid_mux =
(active_master==0) ? m0_arvalid :
(active_master==1) ? m1_arvalid :
m2_arvalid;


assign m0_awready = (active_master==0) ? s_awready : 1'b0;
assign m1_awready = (active_master==1) ? s_awready : 1'b0;
assign m2_awready = (active_master==2) ? s_awready : 1'b0;

assign m0_wready = (active_master==0) ? s_wready : 1'b0;
assign m1_wready = (active_master==1) ? s_wready : 1'b0;
assign m2_wready = (active_master==2) ? s_wready : 1'b0;

assign m0_arready = (active_master==0) ? s_arready : 1'b0;
assign m1_arready = (active_master==1) ? s_arready : 1'b0;
assign m2_arready = (active_master==2) ? s_arready : 1'b0;

assign m0_bvalid = (active_master==0) ? s_bvalid : 1'b0;
assign m1_bvalid = (active_master==1) ? s_bvalid : 1'b0;
assign m2_bvalid = (active_master==2) ? s_bvalid : 1'b0;

assign m0_rvalid = (active_master==0) ? s_rvalid : 1'b0;
assign m1_rvalid = (active_master==1) ? s_rvalid : 1'b0;
assign m2_rvalid = (active_master==2) ? s_rvalid : 1'b0;

assign m0_rdata = s_rdata;
assign m1_rdata = s_rdata;
assign m2_rdata = s_rdata;



axi_slave slave0(
.clk(clk),
.reset(reset),


.S_AWADDR(awaddr_mux),
.S_AWVALID(awvalid_mux),
.S_AWREADY(s_awready),

.S_WDATA(wdata_mux),
.S_WVALID(wvalid_mux),
.S_WREADY(s_wready),

.S_BVALID(s_bvalid),
.S_BREADY(m0_bready | m1_bready | m2_bready),

.S_ARADDR(araddr_mux),
.S_ARVALID(arvalid_mux),
.S_ARREADY(s_arready),

.S_RDATA(s_rdata),
.S_RVALID(s_rvalid),

.S_RREADY(m0_rready | m1_rready | m2_rready)


);

endmodule
