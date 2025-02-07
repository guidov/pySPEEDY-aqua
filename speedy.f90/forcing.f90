!> author: Sam Hatfield, Fred Kucharski, Franco Molteni
!  date: 01/05/2019
!  For setting all time-dependent forcing fields.
module forcing
    use types, only : p

    implicit none

    private
    public set_forcing

contains
    !> Compute forcing fields for the current date and correction terms for
    !  horizontal diffusion
    subroutine set_forcing(state, imode, model_datetime)
        use physical_constants, only : refrh1
        use params
        use physical_constants, only : rgas
        use surface_fluxes, only : set_orog_land_sfc_drag
        use model_control, only : Datetime_t
        use land_model, only : snow_depth2cover
        use mod_radcon, only : albsea, albice, albsn
        use shortwave_radiation, only : get_zonal_average_fields
        use longwave_radiation, only : radset
        use humidity, only : get_qsat
        use model_state, only : ModelState_t

        type(ModelState_t), intent(inout) :: state

        integer, intent(in) :: imode !! Mode -> 0 = initialization step, 1 = daily update
        type(Datetime_t), intent(in) :: model_datetime

        real(p), dimension(ix, il) :: corh, tsfc, tref, psfc, qsfc, qref
        real(p) :: gamlat(il)
        real(p) :: tyear = 0.22 !! The fraction of the current year elapsed

        real(p) :: del_co2, pexp
        integer :: i, j, iyear_ref

        ! time variables for interpolation are set by newdate

        ! 1. time-independent parts of physical parametrizations
        if (imode == 0) then
            call radset(state%fband)
            call set_orog_land_sfc_drag(state%phis0, state%forog)

            state%ablco2_ref = state%air_absortivity_co2
        end if

        ! 2. daily-mean radiative forcing
        ! incoming solar radiation
        call get_zonal_average_fields(state)

        ! total surface albedo

        do i = 1, ix
            do j = 1, il
                state%snowc(i, j) = min(1.0, state%snow_depth(i, j) / snow_depth2cover)
                state%alb_land(i, j) = state%alb0(i, j) + state%snowc(i, j) * (albsn - state%alb0(i, j))
                state%alb_sea(i, j) = albsea + state%sice_am(i, j) * (albice - albsea)

                state%alb_surface(i, j) = state%alb_sea(i, j) &
                        + state%fmask_land(i, j) * (state%alb_land(i, j) - state%alb_sea(i, j))
            end do
        end do

        ! linear trend of co2 absorptivity (del_co2: rate of change per year)
        iyear_ref = 1950
        del_co2 = 0.005
        ! del_co2   = 0.0033

        if (state%increase_co2) then
            state%air_absortivity_co2 = state%ablco2_ref * exp(del_co2 * (model_datetime%year + tyear - iyear_ref))
        end if

        ! 3. temperature correction term for horizontal diffusion
        call setgam(gamlat)

        do j = 1, il
            do i = 1, ix
                corh(i, j) = gamlat(j) * state%phis0(i, j)
            end do
        end do
        state%mod_implicit%tcorh = state%mod_spectral%grid2spec(corh)

        ! 4. humidity correction term for horizontal diffusion
        do j = 1, il
            pexp = 1. / (rgas * gamlat(j))
            do i = 1, ix
                tsfc(i, j) = state%fmask_land(i, j) * state%land_temp(i, j) + state%fmask_sea(i, j) * state%sst_am(i, j)
                tref(i, j) = tsfc(i, j) + corh(i, j)
                psfc(i, j) = (tsfc(i, j) / tref(i, j))**pexp
            end do
        end do

        qref = get_qsat(tref, psfc / psfc, -1.0_p)
        qsfc = get_qsat(tsfc, psfc, 1.0_p)

        corh = refrh1 * (qref - qsfc)

        state%mod_implicit%qcorh = state%mod_spectral%grid2spec(corh)
    end subroutine

    !> Compute reference lapse rate as a function of latitude and date
    subroutine setgam(gamlat)
        use physical_constants, only : gamma
        use params
        use physical_constants, only : grav

        real(p), intent(inout) :: gamlat(il) !! The reference lapse rate

        integer :: j

        gamlat(1) = gamma / (1000. * grav)
        do j = 2, il
            gamlat(j) = gamlat(1)
        end do
    end subroutine
end module
